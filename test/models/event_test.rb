require "test_helper"

class EventTest < ActiveSupport::TestCase
	setup do
		@club     = clubs(:test_club)
		@team     = teams(:senior_a)
		@location = locations(:home_court)

		@person     = Person.create!(name: "Ath", surname: "One",
																birthday: 30.years.ago.to_date)
		@membership = Membership.create!(club: @club, person: @person,
																		kind: :athlete, joined_on: Date.current,
																		status: :active)
		@assignment = Assignment.create!(membership: @membership, team: @team,
																		kind: :athlete, starts_on: Date.current,
																		status: :active)
		@match      = Event.create!(club: @club, team: @team, kind: :match,
																location: @location, start_time: Time.current)
	end

	test "#attendees scopes to this event, not team-wide" do
		match_b = Event.create!(club: @club, team: @team, kind: :match,
														location: @location, start_time: 1.week.from_now)
		Attendance.create!(event: @match, assignment: @assignment, status: :present)

		assert_includes     @match.attendees(:athlete),  @assignment
		assert_not_includes match_b.attendees(:athlete), @assignment
	end

	test "#attendees returns Assignments, not Memberships" do
		Attendance.create!(event: @match, assignment: @assignment, status: :present)
		assert_kind_of Assignment, @match.attendees(:athlete).first
	end

	test "#attendees(:athlete) filters by membership kind" do
		coach = create_coach_assignment(team: @team)
		Attendance.create!(event: @match, assignment: @assignment, status: :present)
		Attendance.create!(event: @match, assignment: coach,       status: :present)

		refute_includes @match.attendees(:athlete), coach
		assert_includes @match.attendees(:coach),   coach
	end

	test "#athlete_assginemt_ids returns Assignment UUIDs" do
		Attendance.create!(event: @match, assignment: @assignment, status: :present)
		assert_equal [ @assignment.id ], @match.athlete_assignment_ids
	end

	test "#has_athlete? accepts a Person" do
		Attendance.create!(event: @match, assignment: @assignment, status: :present)
		assert @match.has_athlete?(@person)
	end

	# --- Stat writing ----------------------------------------------------

	test "#check_stats writes a new Stat from a UUID-keyed form" do
		@match.send(:check_stats, [ [ "#{@assignment.id}_0_3", "2" ] ])   # ftm = 2
		stat = @match.stats.find_by(athlete_id: @assignment.id, concept: 3)
		assert_equal 2, stat.value
		assert_equal "athlete", stat.kind
	end

	test "#check_stats updates existing stats without creating duplicates" do
		@match.stats.create!(Stat.build_attrs(
			event_id: @match.id, period: 0, concept: 3,
			kind: :athlete, athlete_id: @assignment.id, value: 1
		))
		@match.send(:check_stats, [ [ "#{@assignment.id}_0_3", "5" ] ])
		assert_equal 1, @match.stats.where(athlete_id: @assignment.id, concept: 3).count
		assert_equal 5, @match.stats.find_by(athlete_id: @assignment.id, concept: 3).value
	end

	test "#check_stats writes stats from numeric concept keys" do
		q1 = Basketball.new.statistics.enum[:q1]        # 25

		@match.send(:check_stats, [ [ "#{@assignment.id}_0_#{q1}", "1" ] ])

		stat = @match.stats.find_by(athlete_id: @assignment.id, concept: q1)
		assert_equal 1, stat.value
	end

	# --- URL & rendering -------------------------------------------------

	test "#attendee_url omits rdx when nil" do
		url = @match.attendee_url(@assignment)
		refute_match(/rdx=/, url)
	end

	test "#attendee_url includes team segment for team events" do
		url = @match.attendee_url(@assignment, rdx: 2)
		assert_includes url, "/teams/#{@team.id}/"
		assert_match(/rdx=2/, url)
	end

	# --- Destroy ---------------------------------------------------------

	test "#unlink does not touch #players (regression)" do
		assert_nothing_raised { @match.destroy }
	end

	private
		def create_coach_assignment(team: @team)
			p = Person.create!(name: "Coach", surname: SecureRandom.hex(2),
												birthday: 35.years.ago.to_date)
			m = Membership.create!(club: team.club, person: p, kind: :coach,
														joined_on: Date.current, status: :active)
			Assignment.create!(membership: m, team:, kind: :head_coach,
												starts_on: Date.current, status: :active)
		end
end
