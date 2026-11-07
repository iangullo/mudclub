# test/models/basketball_test.rb
require "test_helper"

class BasketballTest < ActiveSupport::TestCase
	fixtures :all

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

	# ---------------------------------------------------------------
	# Regression — parse_stats recursion
	# ---------------------------------------------------------------

	test "#parse_stats does not recurse (regression for removed super)" do
		assert_nothing_raised { basketball.parse_stats(@match, {}) }
	end

	test "#parse_stats iterates only present athletes" do
		Attendance.create!(event: @match, assignment: @assignment, status: :present)

		# Absent athlete (never marked present for this event)
		p2 = Person.create!(name: "Absent", surname: "Ath",
												birthday: 30.years.ago.to_date)
		m2 = Membership.create!(club: @club, person: p2, kind: :athlete,
														joined_on: Date.current, status: :active)
		a2 = Assignment.create!(membership: m2, team: @team, kind: :athlete,
														starts_on: Date.current, status: :active)

		stats = { "#{@assignment.id}_0_3" => "2" }  # fta = 2
		basketball.parse_stats(@match, stats)

		assert_equal 2, stats["#{@assignment.id}_0_1"].to_i       # pta derived
		assert_nil stats["#{a2.id}_0_1"]                          # absent untouched
	end

	# ---------------------------------------------------------------
	# Regression — show_shooting_data / self.stats
	# ---------------------------------------------------------------

	test "#show_shooting_data reads via statistics catalog (regression)" do
		stats = Stat.fetch(event_id: @match.id, period: 0, athlete_id: @assignment.id, create: false)
		assert_nothing_raised do
			basketball.send(:show_shooting_data, "FT", stats, :ftm, :fta)
		end
	end

	# ---------------------------------------------------------------
	# Rule limits & period counts
	# ---------------------------------------------------------------

	test "#match_periods is public (Sport delegates via public_send)" do
		u14 = basketball.rules.enum[:u14]
		assert_equal 4, basketball.match_periods(u14)

		three = basketball.rules.enum[:three]
		assert_equal 1, basketball.match_periods(three)
	end

	test "#match_outings returns nil for FIBA (no :outings config)" do
		assert_nil basketball.match_outings(basketball.rules.enum[:fiba])
	end

	test "#match_outings returns a config hash for U14" do
		outings = basketball.match_outings(basketball.rules.enum[:u14])
		assert outings
		assert_equal 4,  outings[:total]   # regular periods
		assert_equal 3,  outings[:first]   # first-quarters rule
		assert_equal 1,  outings[:min]
		assert_equal 2,  outings[:max]
	end

	# ---------------------------------------------------------------
	# outings_table
	# ---------------------------------------------------------------

	test "#outings_table renders a row per present athlete for U14" do
		event = create_u14_match
		athlete = event.team.athletes.first
		Attendance.create!(event:, assignment: athlete, status: :present)

		b = basketball
		outings = b.match_outings(b.rules.enum[:u14])
		table   = b.outings_table(event, outings)

		assert table
		assert_equal 1, table[:rows].size
		assert_equal athlete.number.to_s, table[:rows].first[:items][0][:value]
	end

	# ---------------------------------------------------------------
	# get_shooting_totals — catalog-driven derivation
	# ---------------------------------------------------------------

	test "#get_shooting_totals derives fgm and fga from catalog components" do
		b = basketball

		{
			t2m: 5, t3m: 1,   # fgm = 5 + 1 = 6
			t2a: 9, t3a: 3    # fga = 9 + 3 = 12
		}.each do |concept, value|
			@match.stats.create!(Stat.build_attrs(
				event_id: @match.id, period: 0,
				concept: b.statistics.enum[concept],
				kind: :athlete, athlete_id: @assignment.id, value: value
			))
		end
		stats = @match.stats.reload.to_a

		b.send(:get_shooting_totals, @match.id, @assignment.id, stats)

		fgm = @match.stats.find_by(athlete_id: @assignment.id,
															concept: b.statistics.enum[:fgm])
		fga = @match.stats.find_by(athlete_id: @assignment.id,
															concept: b.statistics.enum[:fga])
		assert_equal 6,  fgm.value
		assert_equal 12, fga.value
	end

	private

	def basketball
		@basketball ||= Sport.find_by(name: "basketball")&.specific ||
										Basketball.new(name: "basketball")
	end

	def create_u14_match
		u14_rules_id = basketball.rules.enum[:u14]
		cat = Category.create!(age_group: "U14", sex: "mixed",
													min_years: 12, max_years: 14,
													rules: u14_rules_id, sport: @team.sport)
		u14 = Team.create!(club: @club, season: @team.season, category: cat,
											division: @team.division, sport: @team.sport,
											homecourt: @location, locked: false)

		p_m = Person.create!(name: "U14", surname: "Ath",
												birthday: 13.years.ago.to_date)
		m = Membership.create!(club: @club, person: p_m, kind: :athlete,
													joined_on: Date.current, status: :active)
		Assignment.create!(membership: m, team: u14, kind: :athlete,
											starts_on: Date.current, status: :active)

		Event.create!(club: @club, team: u14, kind: :match,
									location: @location, start_time: Time.current)
	end
end
