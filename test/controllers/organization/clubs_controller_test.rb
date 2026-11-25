require "test_helper"

class ClubsControllerTest < ActionDispatch::IntegrationTest
	setup do
		@club  = clubs(:test_club)
		@admin = users(:admin_user)
		@admin.update!(role: :admin)
		sign_in @admin
	end

	test "unauthenticated visitor can view public club show but is denied clubs index" do
		sign_out @admin
		Server.reload!

		get club_path(@club)
		assert_redirected_to root_path

		Server.rebuild!("public_clubs_enabled" => true)
		@club.update!(public: true)
		get club_path(@club)
		assert_response :success

		get clubs_path
		assert_redirected_to root_path

		Server.rebuild!("public_directory_enabled" => true)
		get clubs_path
		assert_redirected_to root_path
	end

	test "GET index, show, new, and edit render for system admin" do
		get clubs_path
		assert_response :success

		get club_path(@club)
		assert_response :success

		get new_club_path, headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get edit_club_path(@club), headers: { "Turbo-Frame" => "modal" }
		assert_response :success
	end

	test "POST create builds a new club and rejects duplicate club" do
		assert_difference -> { Club.count }, 1 do
			post clubs_path, params: {
				club: {
					name: "Club Baloncesto Sevilla",
					nick: "CB Sevilla",
					email: "info@cbsevilla.test",
					phone: "+34954000111",
					address: "Av. de la Palmera 1",
					public: true
				}
			}
		end

		created = Club.find_by!(nick: "CB Sevilla")
		assert_redirected_to club_path(created, rdx: 0)
	end

	test "PATCH update modifies club details and enabled_modules" do
		patch club_path(@club), params: {
			club: {
				nick: "Updated Nick",
				public: true
			}
		}

		assert_redirected_to club_path(@club)
		assert_equal "Updated Nick", @club.reload.nick
	end

	test "DELETE destroy removes club and redirects to clubs index" do
		empty_club = Club.create!(name: "Temp Club", nick: "Temp")

		assert_difference -> { Club.count }, -1 do
			delete club_path(empty_club)
		end

		assert_redirected_to clubs_path(rdx: 0)
	end
end
