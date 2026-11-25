require "test_helper"

class DivisionsControllerTest < ActionDispatch::IntegrationTest
	setup do
		@sport = Basketball.find_or_create_by!(name: "basketball")
		@admin = users(:admin_user)
		@admin.update!(role: :admin)
		sign_in @admin
	end

	test "non-admin user is denied access to sport divisions" do
		sign_in users(:alice)
		get sport_divisions_path(@sport.generic)
		assert_redirected_to root_path
	end

	test "GET index, show, new, and edit render for system admin" do
		div = Division.create!(sport: @sport.generic, name: "Primera Nacional")

		get sport_divisions_path(@sport.generic), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get sport_division_path(@sport.generic, div), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get new_sport_division_path(@sport.generic), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get edit_sport_division_path(@sport.generic, div), headers: { "Turbo-Frame" => "modal" }
		assert_response :success
	end

	test "POST create, PATCH update, and DELETE destroy manage sport divisions" do
		assert_difference -> { Division.count }, 1 do
			post sport_divisions_path(@sport.generic), params: {
				division: {
					sport_id: @sport.id,
					name: "Liga EBA"
				}
			}
		end

		created = Division.find_by!(name: "Liga EBA")
		assert_redirected_to sport_path(@sport)

		patch sport_division_path(@sport.generic, created), params: {
			division: {
				name: "Tercera FEB"
			}
		}
		assert_redirected_to sport_path(@sport)
		assert_equal "Tercera FEB", created.reload.name

		assert_difference -> { Division.count }, -1 do
			delete sport_division_path(@sport.generic, created)
		end
		assert_redirected_to sport_path(@sport)
	end
end
