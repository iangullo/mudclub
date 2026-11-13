# test/models/stat_test.rb
require "test_helper"

class StatTest < ActiveSupport::TestCase
	# A minimal fixture graph, built once per test.
	def setup
		suffix = SecureRandom.hex(3)

		@club   = Club.create!(name: "Club #{suffix}", nick: "c#{suffix}")
		@season = Season.create!(start_date: Date.current, end_date: Date.current + 1.year)
		@sport  = Sport.create!(name: "basketball-#{suffix}")

		@category = Category.create!(
			age_group: "U14",
			sex:       "mixed",
			min_years: 12,
			max_years: 14,
			rules:     0,
			sport:     @sport
		)

		@division = Division.create!(name: "Div #{suffix}", sport: @sport)
		@location = Location.create!(name: "Court #{suffix}", practice_court: true)

		@team = Team.create!(
			club:      @club,
			season:    @season,
			category:  @category,
			division:  @division,   # ← must be present
			sport:     @sport,
			homecourt: @location
		)

		@event = Event.create!(
			club:       @club,
			team:       @team,
			kind:       :match,
			location:   @location,
			start_time: Time.current
		)

		@person     = Person.create!(name: "Ath", surname: "One", birthday: 10.years.ago.to_date)
		@membership = Membership.create!(club: @club, person: @person, kind: :athlete, joined_on: Date.current)
		@athlete    = Assignment.create!(membership: @membership, team: @team, kind: :athlete, starts_on: Date.current)
	end

	# ------------------------------------------------------------------
	# build_attrs
	# ------------------------------------------------------------------

	test "build_attrs writes player_id=0 for team stats" do
		attrs = Stat.build_attrs(event_id: @event.id, period: 0, concept: 1,
														kind: :team, value: 5)
		assert_equal 0, attrs[:player_id]
		assert_nil   attrs[:athlete_id]
		assert_equal :team, attrs[:kind]
	end

	test "build_attrs writes player_id=-1 for rival stats" do
		attrs = Stat.build_attrs(event_id: @event.id, period: 0, concept: 1,
														kind: :rival, value: 5)
		assert_equal(-1, attrs[:player_id])
		assert_nil attrs[:athlete_id]
	end

	test "build_attrs writes athlete_id and no player_id for athlete stats" do
		attrs = Stat.build_attrs(event_id: @event.id, period: 0, concept: 3,
														kind: :athlete,
														athlete_id: @athlete.id, value: 2)
		assert_equal @athlete.id, attrs[:athlete_id]
		assert_nil   attrs[:player_id]
	end

	# ------------------------------------------------------------------
	# Validations
	# ------------------------------------------------------------------

	test "athlete stat requires athlete_id" do
		stat = Stat.new(Stat.build_attrs(event_id: @event.id, period: 0,
																		concept: 3, kind: :athlete,
																		athlete_id: nil, value: 2))
		refute stat.valid?
		assert stat.errors.added?(:athlete, :blank)
	end

	test "team stat rejects athlete_id" do
		stat = Stat.new(
			event_id:      @event.id,
			period:        0,
			concept:       1,
			kind:          :team,
			player_id:     0,
			athlete_id: @athlete.id,   # ← deliberately wrong
			value:         2
		)

		refute stat.valid?
		assert stat.errors.added?(:athlete, :present)
	end

	test "team stat does not require a Player row with id 0" do
		stat = Stat.new(Stat.build_attrs(event_id: @event.id, period: 0,
																		concept: 1, kind: :team, value: 2))
		assert stat.valid?, stat.errors.full_messages.inspect
	end

	# ------------------------------------------------------------------
	# fetch — DB path
	# ------------------------------------------------------------------

	test "fetch creates a new team stat when nothing matches" do
		results = Stat.fetch(event_id: @event.id, period: 0, concept: 1, kind: :team)
		assert_equal 1, results.size
		refute results.first.persisted?
		assert_equal 0, results.first.player_id
		assert results.first.kind_team?
	end

	test "fetch with create: false returns empty array" do
		results = Stat.fetch(event_id: @event.id, period: 0, concept: 1,
												kind: :team, create: false)
		assert_equal [], results
	end

	test "fetch finds an existing stat by event/period/concept/kind" do
		existing = Stat.create!(Stat.build_attrs(event_id: @event.id, period: 0,
																						concept: 1, kind: :team, value: 42))
		results = Stat.fetch(event_id: @event.id, period: 0, concept: 1, kind: :team)
		assert_equal [ existing.id ], results.map(&:id)
		assert_equal 42, results.first.value
	end

	test "fetch for athlete looks up by athlete_id" do
		existing = Stat.create!(
			Stat.build_attrs(event_id: @event.id, period: 0, concept: 3,
											kind: :athlete,
											athlete_id: @athlete.id, value: 2)
		)
		results = Stat.fetch(event_id: @event.id, period: 0, concept: 3,
												kind: :athlete, athlete_id: @athlete.id)
		assert_equal [ existing.id ], results.map(&:id)
	end

	test "fetch raises when kind: :athlete is requested without athlete_id" do
		assert_raises(ArgumentError) do
			Stat.fetch(event_id: @event.id, period: 0, concept: 3, kind: :athlete)
		end
	end

	# ------------------------------------------------------------------
	# fetch — in-memory path
	# ------------------------------------------------------------------

	test "fetch with stats: Array issues zero SQL queries" do
		a = Stat.create!(Stat.build_attrs(event_id: @event.id, period: 0,
																			concept: 1, kind: :team, value: 10))
		b = Stat.create!(Stat.build_attrs(event_id: @event.id, period: 1,
																			concept: 1, kind: :team, value: 20))

		queries = []
		subscriber = lambda do |_name, _s, _f, _id, payload|
			queries << payload[:sql] unless payload[:name] == "SCHEMA"
		end

		ActiveSupport::Notifications.subscribed(
			subscriber, "sql.active_record"
		) do
			results = Stat.fetch(event_id: @event.id, period: 0, concept: 1,
													kind: :team, stats: [ a, b ], create: false)
			assert_equal [ a ], results
		end
		assert_equal 0, queries.size, "expected no SQL, got #{queries.inspect}"
	end

	test "fetch does not mutate the caller's stats array" do
		loaded = []
		Stat.fetch(event_id: @event.id, period: 0, concept: 1,
							kind: :team, stats: loaded, create: true)
		assert_equal [], loaded
	end

	# ------------------------------------------------------------------
	# Legacy shim
	# ------------------------------------------------------------------

	test "fetch(player_id: 0) is deprecated but resolves to team" do
		results = nil
		assert_deprecated(/Stat/, Rails.deprecator) do
			results = Stat.fetch(event_id: @event.id, period: 0, concept: 1,
													player_id: 0, create: false)
		end
		assert_equal [], results
	end

	test "fetch(player_id: -1) is deprecated but resolves to rival" do
		assert_deprecated(/Stat/, Rails.deprecator) do
			Stat.fetch(event_id: @event.id, period: 0, concept: 1,
								player_id: -1, create: false)
		end
	end

	test "fetch(player_id: <player>) resolves to the matching athlete assignment" do
		legacy_player = Player.create!(
			person_id: @person.id,          # ← explicit — has_one doesn't infer from person: @person
			club_id:   @club.id,
			number:    7
		)

		stat = nil
		assert_deprecated(/Stat/, Rails.deprecator) do
			results = Stat.fetch(event_id: @event.id, period: 0, concept: 3,
													 player_id: legacy_player.id)
			stat = results.first
		end

		assert_equal :athlete, stat.kind.to_sym
		assert_equal @athlete.id, stat.athlete_id
	end

	# ------------------------------------------------------------------
	# Scopes
	# ------------------------------------------------------------------

	test "for_team / for_rival / for_athletes scoping" do
		Stat.create!(Stat.build_attrs(event_id: @event.id, period: 0, concept: 1,
																	kind: :team, value: 1))
		Stat.create!(Stat.build_attrs(event_id: @event.id, period: 0, concept: 1,
																	kind: :rival, value: 2))
		Stat.create!(Stat.build_attrs(event_id: @event.id, period: 0, concept: 3,
																	kind: :athlete,
																	athlete_id: @athlete.id, value: 3))

		assert_equal 1, Stat.for_team.count
		assert_equal 1, Stat.for_rival.count
		assert_equal 1, Stat.for_athletes.count
		assert_equal 3, Stat.for_event(@event).count
	end

	test "for_athlete filters correctly by UUID" do
		Stat.create!(Stat.build_attrs(event_id: @event.id, period: 0, concept: 3,
																	kind: :athlete,
																	athlete_id: @athlete.id, value: 3))
		assert_equal 1, Stat.for_athlete(@athlete).count
	end
end
