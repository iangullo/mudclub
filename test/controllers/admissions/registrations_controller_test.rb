require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
	setup do
		Server.reload!
		@team  = teams(:senior_a)
		@club  = @team.club
		@team.season.update!(end_date: 6.months.from_now.to_date) if @team.season.end_date < Date.current
		@team.update!(locked: false)
		@club.update!(public: true)
		Server.current.enable_module!(:admissions) if Server.current.respond_to?(:enable_module!)
		@club.enable_module!(:admissions) if @club.respond_to?(:enable_module!)
		@admin = users(:admin_user)
		@admin.update!(role: :admin)
	end

	# ─── Authorization ───────────────────────────────────────

	test "unauthenticated visitor is denied access to club registrations index" do
		get club_registrations_path(@club)
		assert_redirected_to root_path
	end

	test "system admin can view club registrations index" do
		sign_in @admin
		get club_registrations_path(@club)
		assert_response :success
	end

	# ─── Public / Anonymous Registration Flow ────────────────

	test "anonymous visitor can open new registration and submit an adult draft" do
		get new_club_team_registration_path(@club, @team, kind: :athlete)
		assert_response :success

		assert_difference [ -> { Registration.count }, -> { AdmissionPerson.count } ], 1 do
			post club_team_registrations_path(@club, @team), params: {
				kind: "athlete",
				registration: {
					kind: "athlete",
					requested_team_id: @team.id,
					candidate_attributes: {
						name: "Elena",
						surname: "Vega",
						dni: "44444444E",
						email: "elena@mudclub.test",
						phone: "+34611000044",
						birthday: "1998-05-10"
					}
				}
			}
		end

		reg = Registration.order(:created_at).last
		assert_equal "Elena", reg.candidate.name
		assert reg.status_draft?
		assert_not_nil reg.access_token
		assert_redirected_to club_team_registration_path(@club, @team, reg, token: reg.access_token), flash.to_h.inspect
	end

	test "anonymous visitor can submit a minor registration with guardian1" do
		assert_difference -> { Registration.count }, 1 do
			assert_difference -> { AdmissionPerson.count }, 2 do
				post club_team_registrations_path(@club, @team), params: {
					kind: "athlete",
					registration: {
						kind: "athlete",
						requested_team_id: @team.id,
						candidate_attributes: {
							name: "Mateo",
							surname: "Ruiz",
							birthday: 10.years.ago.to_date.to_s
						},
						guardian1_attributes: {
							name: "Carlos",
							surname: "Ruiz",
							email: "carlos.ruiz@mudclub.test",
							phone: "+34611000055"
						}
					}
				}
			end
		end

		reg = Registration.order(:created_at).last
		assert reg.candidate.minor?
		assert_equal "Carlos", reg.guardian1.name
		assert reg.requester_guardian?
	end

	# ─── Token-Based Requester Lifecycle ─────────────────────

	test "requester with valid token can view, send_for_review, and cancel a registration" do
		reg = build_draft_registration(name: "Paula", surname: "Sanz", email: "paula@mudclub.test")

		# View with token
		get club_team_registration_path(@club, @team, reg, token: reg.access_token)
		assert_response :success

		# Send for review
		patch send_for_review_club_registration_path(@club, reg, token: reg.access_token)
		assert_redirected_to club_team_registration_path(@club, @team, reg, token: reg.access_token)
		assert reg.reload.status_under_review?

		# Cancel -> transitions to :cancelled and anonymizes PII inline
		patch cancel_club_registration_path(@club, reg, token: reg.access_token)
		assert_redirected_to root_path
		reg.reload
		assert reg.status_cancelled?
		assert_not_nil reg.anonymized_at
		assert_nil reg.candidate.reload.email
	end

	# ─── Manager Review, Request Information, Reject & Approve ──

	test "manager can request information and reject a registration with inline anonymization" do
		sign_in @admin
		reg = build_draft_registration(name: "Diego", surname: "Castro", email: "diego@mudclub.test")
		reg.send_for_review!

		assert_difference -> { reg.messages.count }, 1 do
			patch request_information_club_registration_path(@club, reg), params: {
				message: "Please attach your signed ID card."
			}
		end

		assert_redirected_to club_team_registration_path(@club, @team, reg)
		assert reg.reload.status_awaiting_requester?

		# Reject -> transitions to :rejected and anonymizes PII inline
		patch reject_club_registration_path(@club, reg), params: {
			message: "Incomplete documentation"
		}

		assert_redirected_to club_team_registrations_path(@club, @team)
		reg.reload
		assert reg.status_rejected?
		assert_not_nil reg.anonymized_at
		assert_nil reg.candidate.reload.email
	end

	test "manager can approve an under_review registration and promote candidate to Person and Membership" do
		sign_in @admin
		reg = build_draft_registration(
			name: "Nuria",
			surname: "Blanco",
			dni: "33333333N",
			email: "nuria@mudclub.test"
		)
		reg.send_for_review!

		assert_difference [ -> { Person.count }, -> { Membership.count }, -> { Assignment.count } ], 1 do
			patch approve_club_registration_path(@club, reg)
		end

		assert_redirected_to club_team_registration_path(@club, @team, reg)
		assert reg.reload.status_approved?

		created_person = Person.find_by!(dni: "33333333N")
		assert_equal "Nuria", created_person.name
		assert created_person.memberships.for_club(@club).of_kind(:athlete).exists?
		assert created_person.assignments.where(team: @team).exists?
	end

	private
		def build_draft_registration(name:, surname:, email:, dni: nil)
			candidate = AdmissionPerson.create!(
				name: name,
				surname: surname,
				email: email,
				dni: dni,
				birthday: "2000-01-15"
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
