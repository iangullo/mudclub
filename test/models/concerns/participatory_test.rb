require "test_helper"

class ParticipatoryTest < ActiveSupport::TestCase
	setup do
		@person = people(:bob)
		@club   = clubs(:test_club)
		@member = Membership.create!(
			person: @person,
			club: @club,
			kind: :athlete,
			status: :pending,
			joined_on: Date.new(2025, 9, 1)
		)
	end

	test "enforces valid status transitions and rejects illegal jumps" do
		# pending -> active
		assert @member.activate!(Date.new(2025, 9, 1))
		assert @member.reload.active?

		# active -> suspended -> active
		assert @member.suspend!(Date.new(2025, 10, 1))
		assert @member.reload.suspended?
		assert @member.reinstate!(Date.new(2025, 11, 1))
		assert @member.reload.active?

		# active -> terminated
		term_date = Date.new(2026, 6, 30)
		assert @member.terminate!(term_date)
		assert @member.reload.terminated?
		assert_equal term_date, @member.ends_on

		# archived is terminal
		@member.update!(status: :archived)
		refute @member.activate!
		refute @member.suspend!
	end

	test "active_on?, current?, open?, and duration evaluate date bounds accurately" do
		@member.update!(status: :active, joined_on: Date.new(2025, 9, 1), left_on: nil)

		assert @member.open?
		assert @member.started?
		assert @member.active_on?(Date.new(2025, 9, 1))
		refute @member.active_on?(Date.new(2025, 8, 31))

		@member.update!(left_on: Date.new(2026, 5, 31))
		refute @member.open?
		assert @member.active_on?(Date.new(2026, 5, 31))
		refute @member.active_on?(Date.new(2026, 6, 1))
		assert_equal (Date.new(2026, 5, 31) - Date.new(2025, 9, 1)), @member.duration
	end

	test "p_email and p_phone include responsible adults when person is a minor" do
		guardian = Person.create!(name: "Tutor", surname: "Legal", email: "tutor@mudclub.test", phone: "+34600111222")
		minor    = Person.create!(name: "Niño", surname: "Menor", birthday: 12.years.ago.to_date, email: "minor@mudclub.test")
		Relationship.create!(person: minor, related_person: guardian, kind: :parent)

		minor_member = Membership.create!(person: minor, club: @club, kind: :athlete, status: :active, joined_on: Date.current)

		assert_includes minor_member.p_email, "tutor@mudclub.test"
		assert_includes minor_member.p_email, "minor@mudclub.test"
		assert_includes minor_member.p_phone, "+34600111222"
	end
end
