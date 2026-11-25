require "test_helper"

class DrillTest < ActiveSupport::TestCase
	setup do
		@coach    = Coach.first || Coach.create!(club: clubs(:test_club), name: "Test Coach")
		@sport    = Basketball.find_or_create_by!(name: "basketball")
		@category = DrillCategory.create!(name: "Shooting", sport: @sport.generic)
	end

	test "validates presence of name and formats nice_string" do
		invalid = Drill.new(sport: @sport.generic, category: @category, coach: nil)
		refute invalid.valid?
		assert invalid.errors[:name].any?

		drill = Drill.create!(name: "3-Man Weave", sport: @sport.generic, category: @category, coach: @coach)
		assert_equal "#{@category.name} | 3-Man Weave", drill.nice_string
	end

	test "rebuild populates attributes, skills, steps, and targets" do
		drill = Drill.new(sport: @sport.generic, coach: @coach)
		drill.rebuild({
			name: "Transition Layups",
			description: "Full court fast break",
			material: "4 balls, 2 cones",
			court_mode: "full",
			category_id: "Fast Break",
			skills_attributes: {
				"0" => { concept: "Dribbling" },
				"1" => { concept: "Passing" }
			},
			steps_attributes: {
				"0" => { order: 1, explanation: "Outlet pass to wing" }
			}
		})
		drill.save!

		assert_equal "Transition Layups", drill.name
		assert_equal 2, drill.skills.count
		assert_equal 1, drill.steps.count
		assert_equal "Dribbling; Passing", drill.print_skills
	end

	test "search and filter scope drills by name, category, and skill" do
		skill = Skill.create!(concept: "Pick and Roll")
		d1 = Drill.create!(name: "High Ball Screen", sport: @sport.generic, category: @category, skills: [ skill ], coach: @coach)
		d2 = Drill.create!(name: "Box Out Rebound", sport: @sport.generic, category: @category, coach: @coach)

		assert_includes Drill.search("Screen"), d1
		refute_includes Drill.search("Screen"), d2

		assert_includes Drill.search("s Pick"), d1
		refute_includes Drill.search("s Pick"), d2

		filtered = Drill.filter({ "name" => "Box", "category_id" => @category.id.to_s })
		assert_includes filtered, d2
		refute_includes filtered, d1
	end
end
