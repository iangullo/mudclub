require "test_helper"

class DrillCategorySkillTargetTest < ActiveSupport::TestCase
	setup do
		@coach = Coach.first || Coach.create!(club: clubs(:test_club), name: "Test Coach")
		@sport = Basketball.find_or_create_by!(name: "basketball")
	end

	test "DrillCategory titleizes name on save and fetch finds or creates" do
		cat = DrillCategory.fetch("ball handling", sport: @sport.generic)
		assert_equal "Ball Handling", cat.name
		assert_equal cat, DrillCategory.fetch("ball handling", sport: @sport.generic)
	end

	test "Skill.fetch resolves by id or concept search" do
		skill = Skill.create!(concept: "Eurostep")
		assert_equal skill, Skill.fetch({ id: skill.id })
		assert_equal skill, Skill.fetch({ concept: "Euro" })
	end

	test "Target.passed deduplicates concepts while preserving _destroy entries" do
		passed = Target.passed({
			"0" => { target_attributes: { concept: "Spacing" } },
			"1" => { target_attributes: { concept: "Spacing" } },
			"2" => { _destroy: "1", target_attributes: { concept: "Spacing" } }
		})

		assert_equal 2, passed.size
	end
end
