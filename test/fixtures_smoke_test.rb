require "test_helper"

class FixturesSmokeTest < ActiveSupport::TestCase
	EXPECTED = {
		Sport:    1,
		Season:   2,
		Location: 2,
		Club:     3,
		Category: 2,
		Division: 2,
		Person:   2,
		User:     1,
		Drill:    1,
		Team:     4,
		Event:    3,
		Task:     2,
		Step:     2,
		Skill:    2,
		Target:   1
	}.freeze

	test "all fixtures load with the expected counts" do
		EXPECTED.each do |key, expected|
			model  = key.to_s.constantize
			actual = model.count
			assert_equal expected, actual,
			"expected #{expected} #{model.name} rows, got #{actual}"
		end
	end
end
