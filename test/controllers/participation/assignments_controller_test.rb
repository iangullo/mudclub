require "test_helper"

class AssignmentsControllerTest < ActionDispatch::IntegrationTest
	setup do
		@club  = clubs(:test_club)
		@team  = teams(:senior_a)
		@admin = users(:admin_user)
		@admin.update!(role: :admin)
		sign_in @admin
	end

	# ─── Authorization ───────────────────────────────────────

	test "unauthenticated visitor is denied access to club assignments index" do
		sign_out @admin
		get club_assignments_path(@club, kind: :athletes)
		assert_redirected_to root_path
	end

	# ─── Index & Show ────────────────────────────────────────

	test "GET index renders active assignments for club" do
		get club_assignments_path(@club, kind: :athletes)
		assert_response :success
	end

	test "GET show renders assignment details" do
		member = Membership.create!(
			person: people(:alice),
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)
		assignment = Assignment.create!(
			membership: member,
			team: @team,
			kind: :athlete,
			status: :active,
			starts_on: Date.current,
			number: "12"
		)

		get club_team_assignment_path(@club, @team, assignment)
		assert_response :success
	end

	# ─── Create (Flow A: Existing Membership) ────────────────

	test "POST create builds assignment for an existing membership when member_id is passed" do
		member = Membership.create!(
			person: people(:alice),
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		assert_no_difference [ -> { Person.count }, -> { Membership.count } ] do
			assert_difference -> { Assignment.count }, 1 do
				post club_team_assignments_path(@club, @team), params: {
					kind: "athlete",
					member_id: member.id,
					assignment: {
						kind: "athlete",
						number: "14",
						person_attributes: {
							id: people(:alice).id,
							name: people(:alice).name,
							surname: people(:alice).surname
						}
					}
				}
			end
		end

		created = Assignment.order(:created_at).last
		assert_equal member, created.membership
		assert_equal @team, created.team
		assert_equal "14", created.number
		assert_response :redirect
	end

	# ─── Create (Flow B: New Person vs. Reused Person/Member) ─

	test "POST create builds Person, Membership, and Assignment when no match exists" do
		assert_difference [ -> { Person.count }, -> { Membership.count }, -> { Assignment.count } ], 1 do
			post club_team_assignments_path(@club, @team), params: {
				kind: "athlete",
				assignment: {
					kind: "athlete",
					number: "23",
					person_attributes: {
						name: "Sofía",
						surname: "Méndez",
						dni: "77777777S",
						email: "sofia@mudclub.test",
						birthday: "2006-09-15"
					}
				}
			}
		end

		created = Assignment.order(:created_at).last
		assert_equal "Sofía", created.person.name
		assert_equal "77777777S", created.person.dni
		assert_equal "23", created.number
		assert_response :redirect
	end

	test "POST create reuses existing Person and active Membership on exact identifier match" do
		alice = people(:alice)
		existing_member = Membership.create!(
			person: alice,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		assert_no_difference [ -> { Person.count }, -> { Membership.count } ] do
			assert_difference -> { Assignment.count }, 1 do
				post club_team_assignments_path(@club, @team), params: {
					kind: "athlete",
					assignment: {
						kind: "athlete",
						number: "8",
						person_attributes: {
							dni: alice.dni,
							name: alice.name,
							surname: alice.surname
						}
					}
				}
			end
		end

		created = Assignment.order(:created_at).last
		assert_equal existing_member, created.membership
		assert_equal "8", created.number
		assert_response :redirect
	end

	test "POST create renders merge offer (422) when strong identifier matches a different name" do
		alice = people(:alice)

		assert_no_difference [ -> { Person.count }, -> { Membership.count }, -> { Assignment.count } ] do
			post club_team_assignments_path(@club, @team), params: {
				kind: "athlete",
				assignment: {
					kind: "athlete",
					person_attributes: {
						dni: alice.dni,
						name: "Different Name",
						surname: alice.surname
					}
				}
			}
		end

		assert_response :unprocessable_entity
	end

	# ─── Update & Status-Only Transition ─────────────────────

	test "PATCH update modifies jersey number, notes, and person attributes" do
		member = Membership.create!(
			person: people(:bob),
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)
		assignment = Assignment.create!(
			membership: member,
			team: @team,
			kind: :athlete,
			status: :active,
			starts_on: Date.current,
			number: 5
		)

		patch club_team_assignment_path(@club, @team, assignment), params: {
			assignment: {
				number: "00",
				notes: "Captain for season",
				person_attributes: {
					id: people(:bob).id,
					address: "Plaza Nueva 3"
				}
			}
		}

		assert_response :redirect
		assert_equal "00", assignment.reload.number
		assert_equal "Captain for season", assignment.notes.to_plain_text
		assert_equal "Plaza Nueva 3", people(:bob).reload.address
	end

	test "PATCH update with status_only transitions assignment status" do
		member = Membership.create!(
			person: people(:bob),
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)
		assignment = Assignment.create!(
			membership: member,
			team: @team,
			kind: :athlete,
			status: :active,
			starts_on: Date.current
		)

		patch club_team_assignment_path(@club, @team, assignment), params: {
			assignment: {
				status: "suspended"
			}
		}

		assert_response :redirect
		assert assignment.reload.status_suspended?
	end
end
