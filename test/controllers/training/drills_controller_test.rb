require "test_helper"

class DrillsControllerTest < ActionDispatch::IntegrationTest
	setup do
		Server.reload!
		@coach    = Coach.first || Coach.create!(club: clubs(:test_club), name: "Coach")
		@sport    = Basketball.find_or_create_by!(name: "basketball")
		@category = DrillCategory.create!(name: "Offense", sport: @sport.generic)
		@admin    = users(:admin_user)
		@admin.update!(role: :admin)
		member = Membership.create!(
			person: @admin.person,
			club: teams(:senior_a).club,
			kind: :coach,
			status: :active,
			joined_on: 1.month.ago.to_date
		)
		Assignment.create!(
			membership: member,
			team: teams(:senior_a),
			kind: :head_coach,
			status: :active,
			starts_on: 1.month.ago.to_date
		)
		sign_in @admin
	end

	test "GET index, show, new, edit, and versions render for authenticated user" do
		drill = Drill.create!(
			name: "5-Out Motion",
			sport: @sport.generic,
			category: @category,
			coach: @coach,
			author: @admin.person
		)

		get drills_path
		assert_response :success

		get drill_path(drill)
		assert_response :success

		get new_drill_path
		assert_response :success

		get edit_drill_path(drill)
		assert_response :success

		get versions_drill_path(drill), headers: { "Turbo-Frame" => "modal" }
		assert_response :success
	end

	test "POST create, PATCH update, and DELETE destroy manage drills" do
		assert_difference -> { Drill.count }, 1 do
			post drills_path, params: {
				drill: {
					name: "Diamond Press Break",
					sport_id: @sport.id,
					author_id: @admin.person.id,
					category_id: @category.name,
					court_mode: "full",
					description: "Full court press attack",
					skills_attributes: {
						"0" => { concept: "Passing" }
					}
				}
			}
		end

		created = Drill.find_by!(name: "Diamond Press Break")
		assert_redirected_to drill_path(created)

		patch drill_path(created), params: {
			drill: {
				name: "Diamond Press Break v2",
				category_id: @category.name
			}
		}
		assert_redirected_to drill_path(created)
		assert_equal "Diamond Press Break v2", created.reload.name

		assert_difference -> { Drill.count }, -1 do
			delete drill_path(created)
		end
		assert_redirected_to drills_path
	end

	test "diagram editor actions load and update step svgdata" do
		drill = Drill.create!(
			name: "Pick and Pop",
			sport: @sport.generic,
			category: @category,
			coach: @coach,
			author: @admin.person
		)
		step = drill.steps.create!(order: 1, explanation: "Screen at top")

		get edit_diagram_drill_path(drill, step_id: step.id), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		get load_diagram_drill_path(drill, step_id: step.id), headers: { "Turbo-Frame" => "modal" }
		assert_response :success

		svg_payload = {
			symbols: [ { id: "p1", symbol_id: "player_offense", x: 120, y: 180 } ],
			paths: []
		}.to_json

		patch update_diagram_drill_path(drill, step_id: step.id), params: {
			drill: { svgdata: svg_payload }
		}
		assert_redirected_to edit_drill_path(drill)
		assert_equal 1, step.reload.svgdata["symbols"].size
	end
end
