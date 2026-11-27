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

	# ─── Roster eligibility (fix #1) ──────────────────────────

	test "GET edit_roster includes currently-assigned athletes in the eligible pool" do
		# Assigned athlete — the whole point is that this one must remain selectable
		assigned_person = Person.create!(
			name: "Assigned", surname: "Player", birthday: 20.years.ago.to_date
		)

		assigned_member = Membership.create!(
			person: assigned_person, club: @club, kind: :athlete, status: :active, joined_on: Date.current
		)

		Assignment.create!(
			membership: assigned_member, team: @team, kind: :athlete,
			status: :active, starts_on: Date.current
		)

		# Unassigned eligible athlete — the case that already worked
		unassigned_person = Person.create!(
			name: "Unassigned", surname: "Player", birthday: 20.years.ago.to_date
		)
		unassigned_member = Membership.create!(
			person: unassigned_person, club: @club, kind: :athlete, status: :active, joined_on: Date.current
		)

		get edit_roster_club_team_path(@club, @team), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		eligible_ids = @team.eligible_athlete_memberships.map(&:id)
		assert_includes eligible_ids, assigned_member.id
		assert_match assigned_member.s_name, response.body
		assert_includes eligible_ids, unassigned_member.id,
			"unassigned eligible athletes must be offered for addition"
	end

	test "GET edit_roster pre-checks the checkbox of a currently-assigned athlete" do
		person = Person.create!(name: "Assigned", surname: "Player", birthday: 20.years.ago.to_date)
		member = Membership.create!(
			person: person, club: @club, kind: :athlete, status: :active, joined_on: Date.current
		)
		Assignment.create!(
			membership: member, team: @team, kind: :athlete, status: :active, starts_on: Date.current
		)

		get edit_roster_club_team_path(@club, @team), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		# The roster editor submits *membership* IDs (sync_roster diffs them against the
		# current roster), so the checkbox must exist and must be checked.
		assert_select "input[type='checkbox'][name='team[athlete_membership_ids][]'][value='#{member.id}'][checked]",
			{ count: 1 },
			"currently-assigned athlete must be pre-checked in the roster editor"
	end

	test "GET edit_roster submits membership IDs, never assignment IDs" do
		person = Person.create!(name: "Assigned", surname: "Player", birthday: 20.years.ago.to_date)
		member = Membership.create!(
			person: person, club: @club, kind: :athlete, status: :active, joined_on: Date.current
		)
		assignment = Assignment.create!(
			membership: member, team: @team, kind: :athlete, status: :active, starts_on: Date.current
		)

		get edit_roster_club_team_path(@club, @team), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		assert_select "input[type='checkbox'][name='team[athlete_membership_ids][]']", minimum: 1
		assert_select "input[type='checkbox'][value='#{assignment.id}']", { count: 0 },
			"assignment IDs must not appear in the roster form"
	end
end
