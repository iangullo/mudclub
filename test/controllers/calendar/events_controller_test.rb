require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
	setup do
		@team     = teams(:senior_a)
		@club     = @team.club
		@location = locations(:home_court)
		@admin    = users(:admin_user)
		@admin.update!(role: :admin)

		mgr_member = Membership.create!(
			person: @admin.person,
			club: @club,
			kind: :board_member,
			status: :active,
			joined_on: 1.month.ago.to_date
		)
		Assignment.create!(
			membership: mgr_member,
			kind: :club_manager,
			status: :active,
			starts_on: 1.month.ago.to_date
		)

		sign_in @admin
	end

	# ─── Authorization ───────────────────────────────────────

	test "unauthenticated visitor is denied access to events index" do
		sign_out @admin
		get club_team_events_path(@club, @team)
		assert_redirected_to root_path
	end

	# ─── Index (HTML & ICS) ──────────────────────────────────

	test "GET index renders team calendar in HTML and exports ICS" do
		get club_team_events_path(@club, @team)
		assert_response :success

		get club_team_events_path(@club, @team, format: :ics)
		assert_response :success
		assert_includes response.content_type, "text/calendar"
	end

	# ─── Show (Match, Training, Holiday, ICS) ────────────────

	test "GET show renders match event via Basketball match presenter" do
		match = Event.create!(
			club: @club,
			team: @team,
			kind: :match,
			location: @location,
			start_time: 2.days.from_now,
			end_time: 2.days.from_now + 90.minutes,
			name: "Rival BC"
		)

		get club_team_event_path(@club, @team, match)
		assert_response :success

		get club_team_event_path(@club, @team, match, format: :ics)
		assert_response :success
		assert_includes response.content_type, "text/calendar"
	end

	test "GET show renders training event via Training presenter" do
		training = Event.create!(
			club: @club,
			team: @team,
			kind: :training,
			location: @location,
			start_time: 1.day.from_now
		)

		get club_team_event_path(@club, @team, training)
		assert_response :success
	end

	# ─── Create ──────────────────────────────────────────────

	test "POST create builds a new match event for team" do
		assert_difference -> { Event.count }, 1 do
			post club_team_events_path(@club, @team), params: {
				event: {
					club_id: @club.id,
					team_id: @team.id,
					kind: "match",
					name: "CB Sevilla",
					home: true,
					location_id: @location.id,
					start_date: Date.tomorrow.to_s,
					hour: "18",
					min: "30",
					duration: 90
				}
			}
		end

		created = Event.order(:created_at).last
		assert_equal "CB Sevilla", created.name
		assert_equal @team, created.team
		assert_response :redirect
	end

	# ─── Update (Attendance & Match Stats) ───────────────────

	test "PATCH update records athlete attendance on training event" do
		member = Membership.create!(
			person: people(:bob),
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: 1.month.ago.to_date
		)
		athlete = Assignment.create!(
			membership: member,
			team: @team,
			kind: :athlete,
			status: :active,
			starts_on: 1.month.ago.to_date,
			number: "7"
		)
		training = Event.create!(
			club: @club,
			team: @team,
			kind: :training,
			location: @location,
			start_time: Time.current
		)

		assert_difference -> { Attendance.count }, 1 do
			patch club_team_event_path(@club, @team, training), params: {
				event: {
					athlete_assignment_ids: [ athlete.id ]
				}
			}
		end

		assert_response :redirect
		assert training.attendances.find_by(assignment: athlete)&.present?
	end

	test "PATCH update persists match period scores through Sport::StatWriter" do
		match = Event.create!(
			club: @club,
			team: @team,
			kind: :match,
			location: @location,
			start_time: Time.current,
			name: "CB Triana",
			home: true
		)

		patch club_team_event_path(@club, @team, match), params: {
			event: {
				stats_attributes: {
					"0" => {
						"ours_q1_1" => "18",
						"opps_q1_1" => "14"
					}
				}
			}
		}

		assert_response :redirect
		score = @team.sport.specific.match_score(match.id)
		assert_equal 18, score.dig(:q1, :ours)
		assert_equal 14, score.dig(:q1, :opps)
	end

	# ─── Destroy ─────────────────────────────────────────────

	test "DELETE destroy removes event and redirects to team" do
		training = Event.create!(
			club: @club,
			team: @team,
			kind: :training,
			location: @location,
			start_time: 3.days.from_now
		)

		assert_difference -> { Event.count }, -1 do
			delete club_team_event_path(@club, @team, training)
		end

		assert_redirected_to club_team_path(@club, @team)
	end
end
