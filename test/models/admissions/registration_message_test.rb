require "test_helper"

class RegistrationMessageTest < ActiveSupport::TestCase
	setup do
		@team = teams(:senior_a)
		@club = @team.club
		candidate = AdmissionPerson.create!(
			name: "Mario",
			surname: "Luna",
			email: "mario@mudclub.test",
			birthday: "1998-02-02"
		)
		@registration = Registration.create!(
			club: @club,
			requested_team: @team,
			kind: :athlete,
			status: :under_review,
			requester_kind: :self,
			candidate: candidate,
			requester: candidate
		)
	end

	test "validates body presence" do
		msg = @registration.messages.new(author_kind: :requester, body: "")
		refute msg.valid?
		assert msg.errors[:body].any?
	end

	test "reviewer messages require author_assignment while non-reviewer messages forbid it" do
		reviewer_msg = @registration.messages.new(author_kind: :reviewer, body: "Checking docs")
		refute reviewer_msg.valid?
		assert reviewer_msg.errors[:author_assignment].any?

		member = Membership.create!(
			person: people(:alice),
			club: @club,
			kind: :board_member,
			status: :active,
			joined_on: Date.current
		)
		assignment = Assignment.create!(
			membership: member,
			kind: :club_manager,
			status: :active,
			starts_on: Date.current
		)

		reviewer_msg.author_assignment = assignment
		assert reviewer_msg.valid?

		admin_msg = @registration.messages.new(
			author_kind: :admin,
			author_assignment: assignment,
			body: "Admin note"
		)
		refute admin_msg.valid?
		assert admin_msg.errors[:author_assignment].any?
	end

	test "for_requester returns only shared messages while staff_only returns internal notes" do
		shared = @registration.messages.create!(author_kind: :admin, visibility: :shared, body: "Public reply")
		internal = @registration.messages.create!(author_kind: :admin, visibility: :internal, body: "Internal note")

		assert_includes @registration.messages.for_requester, shared
		refute_includes @registration.messages.for_requester, internal
		assert_includes @registration.messages.staff_only, internal
		refute_includes @registration.messages.staff_only, shared
	end
end
