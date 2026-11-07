# test/models/team_test.rb
require "test_helper"

class TeamTest < ActiveSupport::TestCase
	# Structural shell comes from fixtures
	fixtures :clubs, :sports, :seasons, :categories, :divisions,
					:locations, :teams

	setup do
		@club       = clubs(:test_club)
		@sport      = sports(:basketball)
		@season     = seasons(:current)
		@category   = categories(:senior_mixed)
		@division   = divisions(:local)
		@location   = locations(:home_court)
		@team       = teams(:senior_a)

		@person     = Person.create!(
			name: "Ath", surname: "One",
			birthday: 30.years.ago.to_date
		)
		@membership = Membership.create!(
			club: @club, person: @person,
			kind: :athlete, joined_on: Date.current,
			status: :active
		)
		@assignment = Assignment.create!(
			membership: @membership, team: @team,
			kind: :athlete, starts_on: Date.current,
			status: :active
		)
	end

	# ----------------------------------------------------------------
	# ID contract
	# ----------------------------------------------------------------

	test "#athlete_membership_ids returns membership IDs" do
		assert_equal [ @membership.id.to_s ],
								@team.athlete_membership_ids.map(&:to_s)
	end

	test "#athlete_assignment_ids returns assignment UUIDs" do
		ids = @team.athlete_assignment_ids
		assert_equal [ @assignment.id ], ids
		assert_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/, ids.first)
	end

	test "#athlete_assignment_ids honors current: kwarg" do
		@assignment.terminate!
		assert_equal [], @team.athlete_assignment_ids(current: true)
		assert_equal [ @assignment.id ], @team.athlete_assignment_ids(current: false)
	end

	test "#coach_membership_ids honors current: kwarg" do
		coach_p = Person.create!(name: "Coach", surname: SecureRandom.hex(2),
														birthday: 35.years.ago.to_date)
		coach_m = Membership.create!(
			club: @club, person: coach_p, kind: :coach,
			joined_on: Date.current,
			status: :active                 # ← add
		)
		coach_a = Assignment.create!(
			membership: coach_m, team: @team,
			kind: :head_coach, starts_on: Date.current,
			status: :active                 # ← add
		)

		assert_includes @team.coach_membership_ids, coach_m.id.to_s

		coach_a.terminate!
		refute_includes @team.coach_membership_ids(current: true),  coach_m.id.to_s
		assert_includes @team.coach_membership_ids(current: false), coach_m.id.to_s
	end

	# ----------------------------------------------------------------
	# Roster sync
	# ----------------------------------------------------------------

	test "#rebuild with athlete_membership_ids activates an assignment" do
		new_m = build_athlete_membership(club: @club, birthday: 30.years.ago.to_date)
		@team.rebuild(athlete_membership_ids: [ new_m.id ])

		assert @team.assignments.current
							.where(membership: new_m, kind: :athlete).exists?
	end

	test "#rebuild with empty athlete_membership_ids terminates existing" do
		@team.rebuild(athlete_membership_ids: [])
		refute @team.assignments.current.where(kind: :athlete).exists?
	end

	test "#rebuild with a non-membership ID does not activate a roster entry" do
		assert_raises(ActiveRecord::RecordInvalid) do
			@team.rebuild(athlete_membership_ids: [ @assignment.id ])
		end
	end

	# ----------------------------------------------------------------
	# Eligibility
	# ----------------------------------------------------------------

	test "#eligible_athlete_memberships excludes out-of-category people" do
		senior_ok  = build_athlete_membership(club: @club,
																					birthday: 30.years.ago.to_date)
		too_young  = build_athlete_membership(club: @club,
																					birthday: 15.years.ago.to_date)

		eligible = @team.eligible_athlete_memberships
		assert_includes eligible, senior_ok
		refute_includes eligible, too_young
	end

	test "#optional_athletes does not raise (regression for kwarg typo)" do
		assert_nothing_raised { @team.optional_athletes }
	end

	# ----------------------------------------------------------------
	# Attendance aggregation
	# ----------------------------------------------------------------

	test "#attendance ignores coach attendances" do
		training = Event.create!(club: @club, team: @team, kind: :train, location: @location, start_time: 1.day.ago)
		Attendance.create!(event: training, assignment: @assignment, status: :present)

		coach_p = Person.create!(name: "Coach", surname: SecureRandom.hex(2), birthday: 35.years.ago.to_date)
		coach_m = Membership.create!(club: @club, person: coach_p, kind: :coach, joined_on: Date.current, status: :active)
		coach_a = Assignment.create!(membership: coach_m, team: @team, kind: :head_coach, starts_on: Date.current, status: :active)
		Attendance.create!(event: training, assignment: coach_a, status: :present)

		# Only the athlete's row counts. With 1 athlete and 1 present training,
		# the avg should be 100. If coaches leaked in, it would be 1/2 = 50.
		assert_equal 100, @team.attendance[:sessions][:avg]
	end

	private

	def build_athlete_membership(club:, birthday:)
		p = Person.create!(name: "New", surname: SecureRandom.hex(2), birthday:)
		Membership.create!(club:, person: p, kind: :athlete, joined_on: Date.current, status: :active)
	end
end
