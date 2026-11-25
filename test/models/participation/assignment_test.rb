require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
	setup do
		@person = people(:bob)
		@club   = clubs(:north)
		@team   = teams(:north_senior)

		@membership = Membership.create!(
			person: @person,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.new(2025, 9, 1)
		)
	end

	# ─── Validations ─────────────────────────────────────────

	test "validates jersey number format (1 to 2 digits)" do
		valid_a = Assignment.new(membership: @membership, team: @team, kind: :athlete, starts_on: Date.current, number: "14")
		assert valid_a.valid?

		invalid_a = Assignment.new(membership: @membership, team: @team, kind: :athlete, starts_on: Date.current, number: "123")
		refute invalid_a.valid?
		assert invalid_a.errors[:number].any?
	end

	test "team_required enforces team presence for team-level kinds and absence for club-level kinds" do
		team_role_without_team = Assignment.new(membership: @membership, team: nil, kind: :athlete, starts_on: Date.current)
		refute team_role_without_team.valid?
		assert team_role_without_team.errors[:team].any?

		club_role_with_team = Assignment.new(membership: @membership, team: @team, kind: :president, starts_on: Date.current)
		refute club_role_with_team.valid?
		assert club_role_with_team.errors[:team].any?
	end

	# ─── Upward Avatar Propagation (Assignment -> Membership -> Person) ──

	test "attaching avatar to Assignment propagates all the way up to Membership and Person" do
		assignment = Assignment.create!(
			membership: @membership,
			team: @team,
			kind: :athlete,
			status: :active,
			starts_on: Date.current
		)

		blob = attach_test_image(assignment, filename: "match_day.png")

		assert_equal blob.id, assignment.reload.avatar.blob_id
		assert_equal blob.id, @membership.reload.avatar.blob_id
		assert_equal blob.id, @person.reload.avatar.blob_id
	end

	test "updating Membership avatar later does not overwrite existing Assignment custom avatar" do
		assignment = Assignment.create!(
			membership: @membership,
			team: @team,
			kind: :athlete,
			status: :active,
			starts_on: Date.current
		)

		assignment_blob = attach_test_image(assignment, filename: "team_photo.png")
		membership_blob = attach_test_image(@membership, filename: "club_photo.png")

		assert_equal membership_blob.id, @membership.reload.avatar.blob_id
		assert_equal membership_blob.id, @person.reload.avatar.blob_id
		assert_equal assignment_blob.id, assignment.reload.avatar.blob_id
	end

	# ─── Picture Fallback & Formatting ───────────────────────

	test "picture falls back through Assignment -> Membership -> Person -> kind symbol" do
		assignment = Assignment.create!(
			membership: @membership,
			team: @team,
			kind: :athlete,
			status: :active,
			starts_on: Date.current
		)

		# 1. None attached -> kind symbol Hash
		assert_kind_of Hash, assignment.picture

		# 2. Person avatar attached -> Assignment inherits it
		person_blob = attach_test_image(@person, filename: "person.png")
		assert_equal person_blob.id, assignment.reload.picture.blob_id

		# 3. Membership avatar attached -> Assignment inherits Membership's override
		membership_blob = attach_test_image(@membership, filename: "membership.png")
		assert_equal membership_blob.id, assignment.reload.picture.blob_id
	end

	test "to_s formats athlete jersey number and name" do
		assignment = Assignment.create!(
			membership: @membership,
			team: @team,
			kind: :athlete,
			status: :active,
			starts_on: Date.current,
			number: "7"
		)

		assert_equal " (#7) bob Player", assignment.to_s(style: 2)
	end
end
