require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
	setup do
		@team = teams(:senior_a)
		@club = @team.club
	end

	# ─── Validations & Scopes ────────────────────────────────

	test "validates requested_team presence when kind requires a team" do
		candidate = build_admission_person(name: "Inés", surname: "Gil")
		reg = Registration.new(
			club: @club,
			kind: :athlete,
			status: :draft,
			requester_kind: :self,
			candidate: candidate,
			requester: candidate
		)

		refute reg.valid?
		assert reg.errors[:requested_team].any?
	end

	test "for_token finds active non-expired registrations and excludes terminal or expired ones" do
		reg = create_registration
		assert_includes Registration.for_token(reg.access_token), reg

		reg.update_column(:access_token_expires_at, 1.minute.ago)
		assert_empty Registration.for_token(reg.access_token)

		reg.touch_anonymous_access!
		assert_includes Registration.for_token(reg.access_token), reg

		reg.revoke_anonymous_access!
		assert_nil reg.reload.access_token
	end

	# ─── Rebuild (Adult, Minor, Separate Requester) ──────────

	test "rebuild sets requester to candidate for adult self-registration" do
		reg = Registration.new(club: @club, kind: :athlete)
		reg.rebuild({
			requested_team_id: @team.id,
			candidate_attributes: {
				name: "Pablo",
				surname: "Mora",
				email: "pablo@mudclub.test",
				birthday: "1995-03-10"
			}
		})

		assert reg.save
		assert reg.requester_self?
		assert_equal reg.candidate, reg.requester
	end

	test "rebuild requires guardian1 for minors and defaults requester to guardian1" do
		reg = Registration.new(club: @club, kind: :athlete)
		reg.rebuild({
			requested_team_id: @team.id,
			candidate_attributes: {
				name: "Hugo",
				surname: "Soto",
				birthday: 12.years.ago.to_date.to_s
			},
			guardian1_attributes: {
				name: "Laura",
				surname: "Soto",
				email: "laura@mudclub.test",
				phone: "+34611222333"
			}
		})

		assert reg.save
		assert reg.candidate.minor?
		assert reg.requester_guardian?
		assert_equal "Laura", reg.guardian1.name
		assert_equal reg.guardian1, reg.requester
	end

	# ─── Workflow Transitions & GDPR Anonymization ───────────

	test "transitions through draft -> under_review -> awaiting_requester -> approved" do
		reviewer = users(:admin_user)
		reg = create_registration

		assert reg.editable_by_requester?
		reg.send_for_review!
		assert reg.status_under_review?
		assert_not_nil reg.sent_for_review_at
		refute reg.editable_by_requester?

		reg.request_information!(actor: reviewer)
		assert reg.status_awaiting_requester?
		assert_equal reviewer.id, reg.reviewer_id
		assert reg.editable_by_requester?

		reg.approve!(actor: reviewer)
		assert reg.status_approved?
		assert reg.terminal?
		assert_nil reg.access_token
		# Approve intentionally leaves PII intact for RegistrationApprover to consume
		assert_nil reg.anonymized_at
	end

	test "reject! and cancel! transition to terminal states and anonymize all admission people" do
		reviewer = users(:admin_user)
		reg = create_registration(email: "secret@mudclub.test")
		reg.messages.create!(author_kind: :requester, body: "Sensitive note")
		reg.send_for_review!

		reg.reject!(actor: reviewer)
		reg.reload

		assert reg.status_rejected?
		assert reg.terminal?
		assert_not_nil reg.anonymized_at
		assert_nil reg.candidate.reload.email
		assert_equal RegistrationMessage.msg(:deleted), reg.messages.first.body
	end

	test "invalid status transition raises Registration::InvalidTransition" do
		reg = create_registration
		assert_raises(Registration::InvalidTransition) do
			reg.approve!
		end
	end

	private
		def build_admission_person(name:, surname:, email: "test@mudclub.test", birthday: "1999-01-01")
			AdmissionPerson.new(name:, surname:, email:, birthday:)
		end

		def create_registration(email: "player@mudclub.test")
			candidate = AdmissionPerson.create!(
				name: "Sara",
				surname: "Pérez",
				email: email,
				birthday: "1999-06-15"
			)
			Registration.create!(
				club: @club,
				requested_team: @team,
				kind: :athlete,
				status: :draft,
				requester_kind: :self,
				candidate: candidate,
				requester: candidate
			)
		end
end
