require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
	setup do
		@team  = teams(:senior_a)
		@club  = @team.club
		@admin = users(:admin_user)
		@admin.update!(role: :admin)
		sign_in @admin
	end

	test "GET index, show, new, and edit render for system admin" do
		get club_teams_path(@club)
		assert_response :success

		get club_team_path(@club, @team)
		assert_response :success

		get new_club_team_path(@club), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get edit_club_team_path(@club, @team), headers: { "Turbo-Frame" => "modal" }
		assert_response :success
	end

	test "GET roster, edit_roster, targets, edit_targets, plan, edit_plan, and attendance render" do
		get roster_club_team_path(@club, @team)
		assert_response :success

		get edit_roster_club_team_path(@club, @team), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get targets_club_team_path(@club, @team)
		assert_response :success

		get edit_targets_club_team_path(@club, @team), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get plan_club_team_path(@club, @team)
		assert_response :success

		get edit_plan_club_team_path(@club, @team), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get attendance_club_team_path(@club, @team)
		assert_response :success
	end

	test "POST create, PATCH update, and DELETE destroy manage club teams" do
		cat = Category.new(sport: @team.sport.generic).tap do |c|
			c.rebuild(age_group: "u16", min_years: 15, max_years: 16, sex: "male", rules: "fiba")
			c.save!
		end

		assert_difference -> { Team.count }, 1 do
			post club_teams_path(@club), params: {
				team: {
					club_id: @club.id,
					sport_id: @team.sport.id,
					season_id: @team.season.id,
					category_id: cat.id,
					division_id: @team.division_id,
					nick: "Cadete A",
					homecourt_id: locations(:home_court).id
				}
			}
		end

		created = Team.find_by!(nick: "Cadete A")
		assert_redirected_to club_teams_path(@club)

		patch club_team_path(@club, created), params: {
			team: {
				nick: "Cadete Especial"
			}
		}
		assert_redirected_to club_team_path(@club, created)
		assert_equal "Cadete Especial", created.reload.nick

		assert_difference -> { Team.count }, -1 do
			delete club_team_path(@club, created)
		end
		assert_redirected_to club_teams_path(@club)
	end
end
