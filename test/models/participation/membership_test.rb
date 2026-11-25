require "test_helper"

class MembershipTest < ActiveSupport::TestCase
	setup do
		@person = people(:bob)
		@club   = clubs(:test_club)
		@team   = teams(:senior_a)

		@membership = Membership.create!(
			person: @person,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.new(2025, 9, 1)
		)
	end

	# ─── Validations ─────────────────────────────────────────

	test "kind cannot be changed on update" do
		@membership.kind = :coach
		refute @membership.valid?
		assert @membership.errors.added?(:kind, :readonly)
	end

	# ─── Status Transitions & Cascade ────────────────────────

	test "suspend!, reinstate!, and terminate! cascade to active assignments" do
		assignment = Assignment.create!(
			membership: @membership,
			team: @team,
			kind: :athlete,
			status: :active,
			starts_on: Date.new(2025, 9, 1)
		)

		assert @membership.suspend!(Date.new(2025, 11, 1))
		assert @membership.reload.suspended?
		assert assignment.reload.suspended?

		assert @membership.reinstate!(Date.new(2025, 12, 1))
		assert @membership.reload.active?
		assert assignment.reload.active?

		term_date = Date.new(2026, 5, 31)
		assert @membership.terminate!(term_date)
		assert @membership.reload.terminated?
		assert_equal term_date, @membership.ends_on
		assert assignment.reload.terminated?
		assert_equal term_date, assignment.ends_on
	end

	test "archive_and_anonymize! transitions terminated membership and scrubs person PII" do
		@membership.terminate!(Date.current)
		blob = attach_test_image(@membership, filename: "member_pic.png")

		assert @membership.archive_and_anonymize!
		@membership.reload

		assert_equal "archived", @membership.status
		refute @membership.avatar.attached?
		assert_not_nil @person.reload.anonymized_at
		assert_equal 0, ActiveStorage::Blob.where(id: blob.id).count
	end

	# ─── Overlaps & Merging ──────────────────────────────────

	test "overlaps? detects overlapping date ranges for same person, club, and kind" do
		overlapping = Membership.new(
			person: @person,
			club: @club,
			kind: :athlete,
			joined_on: Date.new(2026, 1, 1)
		)
		assert @membership.overlaps?(overlapping)

		other_club = Membership.new(
			person: @person,
			club: clubs(:north),
			kind: :athlete,
			joined_on: Date.new(2026, 1, 1)
		)
		refute @membership.overlaps?(other_club)
	end

	test "merge_from combines date bounds, adopts missing avatar, and merges assignments" do
		other = Membership.create!(
			person: @person,
			club: @club,
			kind: :athlete,
			status: :terminated,
			joined_on: Date.new(2024, 9, 1),
			left_on: Date.new(2025, 6, 30)
		)
		other_blob = attach_test_image(other, filename: "older_avatar.png")

		a_mine  = Assignment.create!(membership: @membership, team: @team, kind: :athlete, status: :active, starts_on: Date.new(2025, 9, 1))
		a_other = Assignment.create!(membership: other, team: @team, kind: :athlete, status: :terminated, starts_on: Date.new(2024, 9, 1), ends_on: Date.new(2025, 6, 30))

		assert @membership.merge_from(other)
		@membership.reload

		assert_equal Date.new(2024, 9, 1), @membership.joined_on
		assert_equal other_blob.id, @membership.avatar.blob_id
		assert_equal Date.new(2024, 9, 1), a_mine.reload.starts_on
		assert_nil Assignment.find_by(id: a_other.id)
	end

	# ─── Upward Avatar Propagation & Picture Fallback ────────

	test "attaching avatar to Membership propagates up to Person" do
		blob = attach_test_image(@membership, filename: "membership.png")

		assert_equal blob.id, @membership.reload.avatar.blob_id
		assert_equal blob.id, @person.reload.avatar.blob_id
	end

	test "picture falls back from Membership -> Person -> kind symbol" do
		assert_kind_of Hash, @membership.picture

		person_blob = attach_test_image(@person, filename: "person.png")
		assert_equal person_blob.id, @membership.reload.picture.blob_id
	end
end
