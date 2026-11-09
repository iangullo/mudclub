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

	# ─── Form-shaped stat payloads (regression: 2026-11 PATCH 500) ─────
	#
	# EventsController#check_stats hands `params[:event][:stats_attributes]["0"]`
	# straight to Sport#update_stats. That hash mixes:
	#   * metadata ("home", "name")
	#   * period scores keyed by *symbol names* from the catalog ("ours_q1_1")
	#   * athlete stats keyed by "<uuid>_<period>_<concept>"
	#
	# Before the fix, "q1".."ot" were not resolved through the catalog, so every
	# score wrote to period 0, and "opps" fell through translate_player_id as
	# pid==0 → :team. That produced the unique violation on idx_stats_unique_team_rival
	# and collapsed every period into one row.
	#
	# These tests lock the *resolved* behaviour in.

	test "parse_stat_key resolves period symbols through the catalog" do
		b = Basketball.new
		assert_equal [ "ours", 1, "1" ], b.send(:parse_stat_key, "ours_q1_1")
		assert_equal [ "ours", 7, "1" ], b.send(:parse_stat_key, "ours_ot_1")
		assert_equal [ "ours", 0, "1" ], b.send(:parse_stat_key, "ours_tot_1")
		assert_equal [ "ours", 3, "1" ], b.send(:parse_stat_key, "ours_3_1") # raw integer
	end

	test "parse_stat_key rejects metadata and unknown periods" do
		b = Basketball.new
		assert_nil b.send(:parse_stat_key, "home")
		assert_nil b.send(:parse_stat_key, "name")
		assert_nil b.send(:parse_stat_key, "ours_bogus_1")
		assert_nil b.send(:parse_stat_key, "ours_q1")   # 2 parts — legacy form removed
	end

	test "resolve_stat_owner maps ours/opps to team/rival" do
		b = Basketball.new
		assert_equal [ :team,  nil ], b.send(:resolve_stat_owner, "ours", @match.id)
		assert_equal [ :rival, nil ], b.send(:resolve_stat_owner, "opps", @match.id)
	end

	test "resolve_stat_owner passes UUID owners through as :athlete" do
		b = Basketball.new
		uuid = @assignment.id
		assert_equal [ :athlete, uuid ], b.send(:resolve_stat_owner, uuid, @match.id)
	end

	test "update_stats writes period scores to distinct (period, kind) rows" do
		b = Basketball.new
		b.update_stats(
			event_id: @match.id,
			stats_data: {
				"ours_q1_1"  => "13", "ours_q2_1"  => "9",
				"opps_q1_1"  => "14", "opps_q2_1"  => "10",
				"ours_ot_1"  => "4",  "opps_ot_1"  => "6",
				"ours_tot_1" => "26", "opps_tot_1" => "30"
			}
		)

		{
			[ 1, :team ] => 13, [ 2, :team ] => 9,  [ 7, :team ] => 4,  [ 0, :team ] => 26,
			[ 1, :rival ] => 14, [ 2, :rival ] => 10, [ 7, :rival ] => 6,  [ 0, :rival ] => 30
		}.each do |(period, kind), expected|
			stat = @match.stats.find_by(period:, kind: kind.to_s)
			assert stat, "expected a #{kind} stat at period #{period}"
			assert_equal expected, stat.value
		end
	end

	test "update_stats never maps away scores to :team" do
		b = Basketball.new
		b.update_stats(event_id: @match.id, stats_data: { "opps_q1_1" => "14" })

		assert_equal 14, @match.stats.find_by(kind: "rival", period: 1).value
		assert_nil @match.stats.find_by(kind: "team",  period: 1),
											"opps_* must not land on kind: :team"
	end

	test "update_stats drops blank values and skips metadata" do
		b = Basketball.new
		b.update_stats(
			event_id: @match.id,
			stats_data: {
				"home"      => "true",
				"name"      => "Rival",
				"ours_q1_1" => "",
				"ours_q2_1" => "7"
			}
		)

		assert_equal 1, @match.stats.count, "only the real score row should exist"
		assert_nil        @match.stats.find_by(period: 1)
		assert_equal 7,   @match.stats.find_by(period: 2, kind: "team").value
	end

	test "update_stats destroys persisted total when both totals are blank" do
		b = Basketball.new
		b.update_stat(event_id: @match.id, period: 0, concept: :pts, kind: :team,  value: 99)
		b.update_stat(event_id: @match.id, period: 0, concept: :pts, kind: :rival, value: 88)

		b.update_stats(
			event_id: @match.id,
			stats_data: {
				"ours_q1_1"  => "10", "ours_q2_1"  => "12",
				"ours_tot_1" => "",   "opps_tot_1" => ""
			}
		)

		assert_nil @match.stats.find_by(period: 0, kind: "team"),
							"blank total must clear the persisted team total"
		assert_nil @match.stats.find_by(period: 0, kind: "rival"),
							"blank total must clear the persisted rival total"
	end

	test "update_stats preserves totals when they are provided" do
		b = Basketball.new
		b.update_stats(
			event_id: @match.id,
			stats_data: {
				"ours_q1_1"  => "10", "ours_tot_1"  => "51",
				"opps_q1_1"  => "11", "opps_tot_1"  => "53"
			}
		)

		assert_equal 51, @match.stats.find_by(period: 0, kind: "team").value
		assert_equal 53, @match.stats.find_by(period: 0, kind: "rival").value
	end

	test "form payload round-trips through match_score" do
		b = Basketball.new
		b.update_stats(
			event_id: @match.id,
			stats_data: {
				"home"       => "true",
				"ours_q1_1"  => "13", "ours_q2_1"  => "9",  "ours_q3_1"  => "17", "ours_q4_1"  => "12",
				"ours_ot_1"  => "0",  "ours_tot_1" => "51",
				"opps_q1_1"  => "14", "opps_q2_1"  => "10", "opps_q3_1"  => "13", "opps_q4_1"  => "12",
				"opps_ot_1"  => "0",  "opps_tot_1" => "53"
			}
		)

		score = b.match_score(@match.id)

		assert_equal({ ours: 13, opps: 14 }, score[:q1])
		assert_equal({ ours:  9, opps: 10 }, score[:q2])
		assert_equal({ ours: 17, opps: 13 }, score[:q3])
		assert_equal({ ours: 12, opps: 12 }, score[:q4])
		assert_equal({ ours: 51, opps: 53 }, score[:tot])
	end

	test "match_score falls back to computed total when no tot rows exist" do
		b = Basketball.new
		b.update_stats(
			event_id: @match.id,
			stats_data: {
				"ours_q1_1" => "10", "ours_q2_1" => "12",
				"opps_q1_1" => "8",  "opps_q2_1" => "14"
			}
		)

		score = b.match_score(@match.id)
		assert_equal({ ours: 22, opps: 22 }, score[:tot],
								"with no persisted total, :tot must be the sum of periods")
	end
end
