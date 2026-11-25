require "test_helper"

class SlotsControllerTest < ActionDispatch::IntegrationTest
	setup do
		@team     = teams(:senior_a)
		@club     = @team.club
		@season   = @team.season
		@location = locations(:home_court)
		@admin    = users(:admin_user)
		@admin.update!(role: :admin)
		sign_in @admin
	end

	# ─── Authorization ───────────────────────────────────────

	test "unauthenticated visitor is denied access to club slots index" do
		sign_out @admin
		get club_slots_path(@club)
		assert_redirected_to root_path
	end

	# ─── Index & Show ────────────────────────────────────────

	test "GET index renders weekly timetable for practice locations" do
		get club_slots_path(@club, location_id: @location.id, season_id: @season.id)
		assert_response :success
	end

	test "GET show renders training slot details" do
		slot = Slot.create!(
			team: @team,
			season: @season,
			location: @location,
			wday: 2,
			start: Time.utc(2000, 1, 1, 18, 0),
			duration: 90
		)

		get club_slot_path(@club, slot), headers: { "Turbo-Frame" => "modal" }
		assert_response :success
	end

	# ─── Create, Update & Destroy ────────────────────────────

	test "POST create builds a new training slot" do
		assert_difference -> { Slot.count }, 1 do
			post club_slots_path(@club), params: {
				slot: {
					club_id: @club.id,
					team_id: @team.id,
					season_id: @season.id,
					location_id: @location.id,
					wday: 3,
					hour: "19",
					min: "00",
					duration: 90
				}
			}
		end

		created = Slot.order(:created_at).last
		assert_equal 3, created.wday
		assert_equal 90, created.duration
		assert_response :redirect
	end

	test "PATCH update modifies slot duration and weekday" do
		slot = Slot.create!(
			team: @team,
			season: @season,
			location: @location,
			wday: 1,
			start: Time.utc(2000, 1, 1, 17, 30),
			duration: 60
		)

		patch club_slot_path(@club, slot), params: {
			slot: {
				wday: 4,
				duration: 120
			}
		}

		assert_response :redirect
		assert_equal 4, slot.reload.wday
		assert_equal 120, slot.duration
	end

	test "DELETE destroy removes training slot" do
		slot = Slot.create!(
			team: @team,
			season: @season,
			location: @location,
			wday: 5,
			start: Time.utc(2000, 1, 1, 18, 0),
			duration: 75
		)

		assert_difference -> { Slot.count }, -1 do
			delete club_slot_path(@club, slot)
		end

		assert_response :redirect
	end
end
