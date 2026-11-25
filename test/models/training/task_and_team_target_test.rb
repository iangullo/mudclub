require "test_helper"

class TaskAndTeamTargetTest < ActiveSupport::TestCase
	setup do
		@coach    = Coach.first || Coach.create!(club: clubs(:test_club), name: "Test Coach")
		@team     = teams(:senior_a)
		@sport    = @team.sport
		@category = DrillCategory.create!(name: "Conditioning", sport: @sport.generic)
		@drill    = Drill.create!(name: "Suicides", sport: @sport.generic, category: @category, coach: @coach)
		@event    = Event.create!(
			club: @team.club,
			team: @team,
			kind: :training,
			location: locations(:home_court),
			start_time: 1.day.from_now
		)
	end

	test "Task formats duration, headstring, and fetch creates or updates" do
		task = Task.fetch({ order: "1", drill_id: @drill.id.to_s, duration: "15" })
		task.event = @event
		task.save!

		assert_equal "15'", task.s_dur
		assert_equal "01 - #{@drill.nice_string} (15')", task.headstring
		assert_equal @drill.nice_string, task.to_s

		updated = Task.fetch({ id: task.id.to_s, order: "2", drill_id: @drill.id.to_s, duration: "20" })
		assert_equal task.id, updated.id
		assert_equal 20, updated.duration
	end

	test "TeamTarget validates completion bounds, status colors, and nest_create" do
		target = Target.create!(concept: "Zone Defense", focus: :defense, aspect: :collective)
		tt = TeamTarget.new(team: @team, target:, priority: 1, month: 1, completion: 0)
		assert_equal :red, tt.status

		tt.completion = 50
		assert_equal :yellow, tt.status

		tt.completion = 90
		assert_equal :green, tt.status

		tt.completion = 105
		refute tt.valid?

		nested = TeamTarget.nest_create(month: 2, aspect: :individual, focus: :offense)
		assert_equal 2, nested.month
		assert_equal "offense", nested.target.focus
		assert_equal "individual", nested.target.aspect
	end
end
