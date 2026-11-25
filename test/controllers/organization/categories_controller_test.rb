require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
	setup do
		@sport = Basketball.find_or_create_by!(name: "basketball")
		@admin = users(:admin_user)
		@admin.update!(role: :admin)
		sign_in @admin
	end

	test "non-admin user is denied access to sport categories" do
		sign_in users(:alice)
		get sport_categories_path(@sport.generic)
		assert_redirected_to root_path
	end

	test "GET index, show, new, and edit render for system admin" do
		cat = Category.new(sport: @sport.generic).tap do |c|
			c.rebuild(age_group: "u16", min_years: 15, max_years: 16, sex: "male", rules: "fiba")
			c.save!
		end

		get sport_categories_path(@sport.generic), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get sport_category_path(@sport.generic, cat), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get new_sport_category_path(@sport.generic), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get edit_sport_category_path(@sport.generic, cat), headers: { "Turbo-Frame" => "modal" }
		assert_response :success
	end

	test "POST create, PATCH update, and DELETE destroy manage sport categories" do
		assert_difference -> { Category.count }, 1 do
			post sport_categories_path(@sport.generic), params: {
				category: {
					sport_id: @sport.id,
					age_group: "u14",
					min_years: 13,
					max_years: 14,
					sex: "female",
					rules: "u14"
				}
			}
		end

		created = Category.order(:created_at).last
		assert_redirected_to sport_path(@sport)

		patch sport_category_path(@sport.generic, created), params: {
			category: {
				max_years: 15
			}
		}
		assert_redirected_to sport_path(@sport)
		assert_equal 15, created.reload.max_years

		assert_difference -> { Category.count }, -1 do
			delete sport_category_path(@sport.generic, created)
		end
		assert_redirected_to sport_path(@sport)
	end
end
