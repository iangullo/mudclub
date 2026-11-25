require "test_helper"

class StepTest < ActiveSupport::TestCase
	setup do
		@coach    = Coach.first || Coach.create!(club: clubs(:test_club), name: "Test Coach")
		@sport    = Basketball.find_or_create_by!(name: "basketball")
		@category = DrillCategory.create!(name: "Tactics", sport: @sport.generic)
		@drill    = Drill.create!(name: "Horns Set", sport: @sport.generic, category: @category, coach: @coach)
	end

	test "assigns sequential order and copies prior svgdata on initialize" do
		s1 = @drill.steps.create!(
			explanation: "Initial alignment",
			svgdata: {
				symbols: [ { id: "p1", symbol_id: "player_offense", x: 100, y: 200 } ],
				paths: []
			}
		)
		assert_equal 1, s1.order
		assert_equal :combo_svg, s1.representation_type

		s2 = @drill.steps.build
		assert_equal 2, s2.order
		assert_equal 1, s2.svgdata["symbols"].size
		assert_equal :svg, s2.representation_type
	end

	test "validates svgdata structure, symbol positions, and hex colors" do
		bad_step = @drill.steps.build(
			svgdata: {
				symbols: [ { id: "bad", symbol_id: "ball", x: "not-a-number", y: 10, fill: "red" } ],
				paths: [ { id: "path1", points: [ [ 1, 2 ] ], curve: "maybe", style: "zigzag" } ]
			}
		)

		refute bad_step.valid?
		assert bad_step.errors[:svgdata].any?
	end
end
