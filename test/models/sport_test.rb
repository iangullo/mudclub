require "test_helper"

class SportTest < ActiveSupport::TestCase
	setup do
		@club     = clubs(:test_club)
		@sport    = sports(:basketball)
		@season   = seasons(:current)
		@category = categories(:senior_mixed)
		@division = divisions(:local)
		@location = locations(:home_court)
		@team     = teams(:senior_a)

		@person     = Person.create!(name: "Ath", surname: "One", birthday: 30.years.ago.to_date)
		@membership = Membership.create!(club: @club, person: @person, kind: :athlete, joined_on: Date.current, status: :active)
		@assignment = Assignment.create!(membership: @membership, team: @team, kind: :athlete, starts_on: Date.current, status: :active)
		@match      = Event.create!(club: @club, team: @team, kind: :match, location: @location, start_time: Time.current)
	end

	# ─── Delegation & catalog lookups (original) ────────────────────────

	test "#delegate_to_specific raises when self IS the specific" do
		sport = Basketball.new(name: "basketball")
		assert_raises(NotImplementedError) do
			sport.send(:delegate_to_specific, :parse_stats, nil, {})
		end
	end

	test "#concept_id handles all input types" do
		b = Basketball.new
		assert_equal 25, b.send(:concept_id, 25)
		assert_equal 25, b.send(:concept_id, :q1)
		assert_equal 25, b.send(:concept_id, "25")
		assert_equal 25, b.send(:concept_id, "q1")
		assert_equal 1,  b.send(:concept_id, "pts")
	end

	# ─── Stat persistence (original) ────────────────────────────────────

	test "#update_stat creates a team stat when kind is :team" do
		Basketball.new.update_stat(event_id: @match.id, period: 0, concept: :q1,
															kind: :team, value: 12)
		stat = @match.stats.find_by(kind: "team", concept: 25)
		assert_equal 12, stat.value
	end

	test "#update_stat creates an athlete stat when kind is :athlete" do
		assignment = @match.team.athletes.first
		Basketball.new.update_stat(event_id: @match.id, period: 0, concept: :pts,
															kind: :athlete, athlete_id: assignment.id, value: 7)
		stat = @match.stats.find_by(athlete_id: assignment.id, concept: 1)
		assert_equal 7, stat.value
	end

	test "#update_stats iterates a UUID-keyed hash" do
		assignment = @match.team.athletes.first
		Basketball.new.update_stats(
			event_id: @match.id,
			stats_data: {
				"#{assignment.id}_0_3" => "2",
				"#{assignment.id}_0_4" => "1"
			}
		)
		assert_equal 2, @match.stats.find_by(athlete_id: assignment.id, concept: 3).value
		assert_equal 1, @match.stats.find_by(athlete_id: assignment.id, concept: 4).value
	end

	test "#update_stats handles ActionController::Parameters" do
		assignment = @match.team.athletes.first
		params = ActionController::Parameters.new("#{assignment.id}_0_3" => "4")
		Basketball.new.update_stats(event_id: @match.id, stats_data: params)
		assert_equal 4, @match.stats.find_by(athlete_id: assignment.id, concept: 3).value
	end

	# ─── Match score (original) ─────────────────────────────────────────

	test "#match_score reads team & rival rows correctly" do
		b  = Basketball.new
		q1 = b.periods.enum[:q1]

		b.update_stat(event_id: @match.id, period: q1, concept: 1, kind: :team,  value: 30)
		b.update_stat(event_id: @match.id, period: q1, concept: 1, kind: :rival, value: 25)

		score = b.match_score(@match.id)

		assert_equal 30, score.dig(:q1, :ours)
		assert_equal 25, score.dig(:q1, :opps)
		assert_equal 30, score.dig(:tot, :ours)
		assert_equal 25, score.dig(:tot, :opps)
	end

	# ─── HasSettings integration ────────────────────────────────────────
	# Sport includes HasSettings but NOT HasModules — proving the storage
	# contract works on a model with no module layer.

	test "settings are symbol-keyed on read" do
		@sport.update_columns(settings: { "scoring" => { "points" => "goals" } })
		assert_equal "goals", @sport.settings[:scoring][:points]
		assert_nil @sport.settings["scoring"], "reads must be symbol-keyed"
	end

	test "settings returns {} when column is nil" do
		@sport.update_columns(settings: nil)
		assert_equal({}, @sport.settings)
	end

	test "update_settings! preserves unrelated keys" do
		@sport.update_settings!(scoring: { sets: 4 })
		@sport.update_settings!(limits:  { max_subs: 3 })
		@sport.reload
		assert_equal({ sets: 4 },     @sport.settings[:scoring])
		assert_equal({ max_subs: 3 }, @sport.settings[:limits])
	end

	# ─── scoring ────────────────────────────────────────────────────────
	# Regression guard: `scoring` symbolizes :points so it can be used as a
	# catalog enum key, and memoizes per instance so match pages don't
	# re-parse settings on every render.

	test "scoring returns empty structure when unset" do
		@sport.update_columns(settings: {})
		assert_equal({ points: nil, sets: nil }, @sport.scoring)
	end

	test "scoring symbolizes points for enum lookup" do
		@sport.update_columns(settings: { "scoring" => { "points" => "goals", "sets" => 3 } })
		result = @sport.scoring
		assert_equal :goals, result[:points]
		assert_equal 3,      result[:sets]
	end

	test "scoring is memoized per instance" do
		@sport.update_columns(settings: { "scoring" => { "points" => "goals" } })
		first = @sport.scoring

		@sport.update_columns(settings: { "scoring" => { "points" => "tries" } })
		assert_equal first, @sport.scoring
		assert_equal :goals, @sport.scoring[:points],
			"second read must return the memoized value, not re-parse settings"
	end

	# ─── limits ─────────────────────────────────────────────────────────

	test "limits returns empty hash when unset" do
		@sport.update_columns(settings: {})
		assert_equal({}, @sport.limits)
	end

	test "limits_for returns nil for unknown rules" do
		@sport.update_columns(settings: {})
		assert_nil @sport.limits_for(:nonexistent)
	end

	test "limits_for resolves symbol keys" do
		@sport.update_columns(settings: { "limits" => { "subs" => { "max" => 5 } } })
		assert_equal({ max: 5 }, @sport.limits_for(:subs))
	end

	test "limits_for resolves string keys via to_sym" do
		@sport.update_columns(settings: { "limits" => { "subs" => { "max" => 5 } } })
		assert_equal({ max: 5 }, @sport.limits_for("subs"))
	end

	# ─── time_string (pure function) ────────────────────────────────────

	test "time_string formats zero" do
		assert_equal '0"', @sport.time_string(0)
	end

	test "time_string formats seconds only" do
		assert_equal '45"', @sport.time_string(45)
	end

	test "time_string formats minutes and seconds" do
		assert_equal %q(1'30"), @sport.time_string(90)
	end

	test "time_string formats whole hours" do
		assert_equal '1º0"', @sport.time_string(3600)
	end

	test "time_string formats hours, minutes, seconds" do
		assert_equal %q(1º2'5"), @sport.time_string(3725)
	end

	# ─── catalog-backed (needs a specific class, not the Sport record) ──
	# These use Basketball.new because generic_settings reads CATALOGS from
	# the specific class, and calling it on @sport would require a matching
	# Basketball row in the DB (see Sport#specific_instance).

	test "generic_settings returns the expected top-level keys" do
		settings = Basketball.new.generic_settings
		assert_equal %i[rules periods stats scoring limits].sort, settings.keys.sort
	end

	test "generic_settings seeds empty scoring and limits" do
		settings = Basketball.new.generic_settings
		assert_equal({}, settings[:scoring])
		assert_equal({}, settings[:limits])
	end
end
