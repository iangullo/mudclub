require "test_helper"

class CategoryTest < ActiveSupport::TestCase
	setup do
		@sport = sports(:basketball).generic
	end

	# ─── Validations ─────────────────────────────────────────

	test "validates min_years is less than or equal to max_years" do
		valid_range = Category.new(sport: @sport, age_group: "u16", sex: :mixed, min_years: 15, max_years: 16)
		assert valid_range.valid?

		single_year = Category.new(sport: @sport, age_group: "u15", sex: :mixed, min_years: 15, max_years: 15)
		assert single_year.valid?, "single-year categories (min_years == max_years) must be valid"

		unbounded_senior = Category.new(sport: @sport, age_group: "senior", sex: :mixed, min_years: 18, max_years: nil)
		assert unbounded_senior.valid?, "open-ended senior categories (max_years nil) must be valid"

		inverted = Category.new(sport: @sport, age_group: "bad", sex: :mixed, min_years: 18, max_years: 16)
		refute inverted.valid?
		assert inverted.errors[:min_years].any?
	end

	# ─── Birthdate boundary calculations ─────────────────────

	test "oldest and youngest span Jan 1 of (s_year - max_years) through Dec 31 of (s_year - min_years)" do
		u16 = Category.new(sport: @sport, age_group: "u16", sex: :female, min_years: 15, max_years: 16)

		assert_equal Date.new(2010, 1, 1),   u16.oldest(2026)
		assert_equal Date.new(2011, 12, 31), u16.youngest(2026)
		assert_equal "2010 - 2011",        u16.birth_years(2026)
	end

	test "oldest returns nil when max_years is nil or 0 (unbounded senior)" do
		senior = Category.new(sport: @sport, age_group: "senior", sex: :male, min_years: 18, max_years: nil)

		assert_nil senior.oldest(2026)
		assert_equal Date.new(2008, 12, 31), senior.youngest(2026)
		assert_equal "> 2008", senior.birth_years(2026)
	end
end
