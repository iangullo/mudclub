require "test_helper"

class SeasonTest < ActiveSupport::TestCase
	test "name formats single-year and split-year seasons and handles placeholder id 0" do
		all_seasons = Season.new(id: 0, start_date: Date.new(2000, 1, 1), end_date: Date.new(2000, 12, 31))
		single_year = Season.new(id: 10, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 12, 31))
		split_year  = Season.new(id: 11, start_date: Date.new(2026, 9, 1), end_date: Date.new(2027, 6, 30))

		assert_equal Season.val(:all), all_seasons.name
		assert_equal "2026", single_year.name
		assert_equal "2026/27", split_year.name
		assert_equal "2026_27", split_year.name(safe: true)
	end

	test "months returns ordered month pairs or hashes across season span" do
		season = Season.new(start_date: Date.new(2026, 9, 1), end_date: Date.new(2026, 12, 1))

		long_months = season.months(true)
		assert_equal [ 9, 10, 11 ], long_months.map(&:last)

		short_months = season.months(false)
		assert_equal [ { i: 9, name: "SEP" }, { i: 10, name: "OCT" }, { i: 11, name: "NOV" } ], short_months
	end

	test "search_date and search resolve matching season by date or id" do
		season = Season.create!(start_date: Date.new(2030, 9, 1), end_date: Date.new(2031, 6, 30))

		assert_equal season, Season.search_date(Date.new(2030, 11, 15))
		assert_equal season, Season.search(season.id)
		assert_equal season, Season.search("2031-02-10")
	end
end
