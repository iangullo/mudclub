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

	test "#delegate_to_specific raises when self IS the specific" do
		sport = Basketball.new(name: "basketball")
		# Calling a delegating method on the specific class directly should
		# raise — this is the recursion guard working
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
		assert_equal 1, b.send(:concept_id, "pts")
	end

	test "#update_stat creates a team stat when kind is :team" do
		event = @match
		Basketball.new.update_stat(event_id: event.id, period: 0, concept: :q1,
															kind: :team, value: 12)
		stat = event.stats.find_by(kind: "team", concept: 25)
		assert_equal 12, stat.value
	end

	test "#update_stat creates an athlete stat when kind is :athlete" do
		event = @match
		assignment = event.team.athletes.first
		Basketball.new.update_stat(event_id: event.id, period: 0, concept: :pts,
															kind: :athlete, athlete_id: assignment.id, value: 7)
		stat = event.stats.find_by(athlete_id: assignment.id, concept: 1)
		assert_equal 7, stat.value
	end

	test "#update_stats iterates a UUID-keyed hash" do
		event = @match
		assignment = event.team.athletes.first
		Basketball.new.update_stats(
			event_id: event.id,
			stats_data: {
				"#{assignment.id}_0_3" => "2",   # ftm
				"#{assignment.id}_0_4" => "1"    # fta
			}
		)
		assert_equal 2, event.stats.find_by(athlete_id: assignment.id, concept: 3).value
		assert_equal 1, event.stats.find_by(athlete_id: assignment.id, concept: 4).value
	end

	test "#update_stats handles ActionController::Parameters" do
		# Regression: params[:outings] is not a Hash
		event = @match
		assignment = event.team.athletes.first
		params = ActionController::Parameters.new(
			"#{assignment.id}_0_3" => "4"
		)
		Basketball.new.update_stats(event_id: event.id, stats_data: params)
		assert_equal 4, event.stats.find_by(athlete_id: assignment.id, concept: 3).value
	end

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
end
