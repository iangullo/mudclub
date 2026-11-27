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

	test "GET log and DELETE clear_log manage club-scoped audit log without affecting other clubs" do
		other_club = Club.create!(name: "Other Club", nick: "Other")
		club_act   = UserAction.create!(user: @admin, club: @club, kind: :updated, description: "Club action")
		other_act  = UserAction.create!(user: @admin, club: other_club, kind: :updated, description: "Other club action")

		get log_club_path(@club)
		assert_response :success
		assert_select "a.clear-btn[href='#{clear_log_club_path(@club)}'][data-turbo-method='delete'][data-turbo-confirm]"

		assert_difference -> { UserAction.for_club(@club).count }, -1 do
			delete clear_log_club_path(@club)
		end

		assert_redirected_to log_club_path(@club)
		assert_not UserAction.exists?(club_act.id)
		assert UserAction.exists?(other_act.id), "clearing one club's log must not delete another club's actions"
	end

	test "non-manager user is denied access to club log" do
		regular = users(:alice)
		sign_in regular

		get log_club_path(@club)
		assert_redirected_to root_path

		delete clear_log_club_path(@club)
		assert_redirected_to root_path
	end
end
