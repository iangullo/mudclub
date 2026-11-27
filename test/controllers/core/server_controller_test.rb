require "test_helper"

class ServerControllerTest < ActionDispatch::IntegrationTest
	setup do
		@admin = users(:admin_user)
		@admin.update!(role: :admin)
		sign_in @admin
	end

	# ─── Authorization ───────────────────────────────────────

	test "non-admin user is denied access to server administration and logs" do
		sign_in users(:alice)

		get server_path
		assert_redirected_to root_path

		get edit_server_path
		assert_redirected_to root_path

		patch server_path, params: { server: { server_name: "Hacked" } }
		assert_redirected_to root_path

		get log_server_path
		assert_redirected_to root_path

		delete clear_log_server_path
		assert_redirected_to root_path
	end

	# ─── Show, About, Edit & Update ──────────────────────────

	test "GET show, edit, and about render for system admin" do
		get server_path
		assert_response :success

		get edit_server_path, headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get about_server_path, headers: { "Turbo-Frame" => "modal" }
		assert_response :success
	end

	test "PATCH update persists server configuration" do
		Server.reload!
		patch server_path, params: {
			server: {
				server_name: "MudClub Arena",
				time_zone: "Europe/Madrid",
				date_format: "default"
			}
		}

		assert_empty Server.last_errors
		assert_redirected_to server_path
		Server.reload!
		assert_equal "MudClub Arena", Server.server_name
	end

	# ─── Global Audit Log & Clearance ────────────────────────

	test "GET log and DELETE clear_log manage global server audit log" do
		club = clubs(:test_club)
		UserAction.create!(user: @admin, club: nil, kind: :created, description: "Global server action")
		UserAction.create!(user: @admin, club: club, kind: :updated, description: "Club scoped action")

		get log_server_path
		assert_response :success
		assert_select "a.clear-btn[href='#{clear_log_server_path}'][data-turbo-method='delete'][data-turbo-confirm]"

		delete clear_log_server_path
		assert_redirected_to log_server_path
		assert_equal 0, UserAction.count
	end
end
