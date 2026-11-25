require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
	setup do
		@club  = clubs(:test_club)
		@admin = users(:admin_user)
		@admin.update!(role: :admin)
		sign_in @admin
	end

	# ─── Authorization ───────────────────────────────────────

	test "unauthenticated visitor is denied access to club members index" do
		sign_out @admin
		get club_members_path(@club, kind: :athletes)
		assert_redirected_to root_path
	end

	# ─── Index & Show ────────────────────────────────────────

	test "GET index renders active memberships for club" do
		get club_members_path(@club, kind: :athletes)
		assert_response :success
	end

	test "GET show renders membership details" do
		member = Membership.create!(
			person: people(:alice),
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		get club_member_path(@club, member)
		assert_response :success
	end

	# ─── Create (New Person vs. Existing Person vs. Merge Offer) ──

	test "POST create builds a new Person and Membership when no match exists" do
		assert_difference [ -> { Person.count }, -> { Membership.count } ], 1 do
			post club_members_path(@club), params: {
				kind: "athletes",
				membership: {
					kind: "athlete",
					person_attributes: {
						name: "Lucía",
						surname: "Navarro",
						dni: "55555555L",
						email: "lucia@mudclub.test",
						birthday: "2008-04-12"
					}
				}
			}
		end

		created = Membership.order(:created_at).last
		assert_equal "Lucía", created.person.name
		assert_equal "55555555L", created.person.dni
		assert_redirected_to club_members_path(kind: :athlete)
	end

	test "POST create reuses existing Person on exact identifier match" do
		alice = people(:alice)

		assert_no_difference -> { Person.count } do
			assert_difference -> { Membership.count }, 1 do
				post club_members_path(@club), params: {
					kind: "athletes",
					membership: {
						kind: "athlete",
						person_attributes: {
							dni: alice.dni,
							name: alice.name,
							surname: alice.surname
						}
					}
				}
			end
		end

		assert_equal alice, Membership.order(:created_at).last.person
	end

	test "POST create renders merge offer (422) when strong identifier matches a different name" do
		alice = people(:alice)

		assert_no_difference [ -> { Person.count }, -> { Membership.count } ] do
			post club_members_path(@club), params: {
				kind: "athletes",
				membership: {
					kind: "athlete",
					person_attributes: {
						dni: alice.dni,
						name: "Different Person",
						surname: alice.surname
					}
				}
			}
		end

		assert_response :unprocessable_entity
	end

	test "POST create renders validation errors (422) when person surname is missing" do
		assert_no_difference [ -> { Person.count }, -> { Membership.count } ] do
			post club_members_path(@club), params: {
				kind: "athletes",
				membership: {
					kind: "athlete",
					person_attributes: {
						name: "Incomplete",
						surname: ""
					}
				}
			}
		end

		assert_response :unprocessable_entity
	end

	# ─── Update & Status-Only Transition ─────────────────────

	test "PATCH update modifies person attributes and membership notes" do
		member = Membership.create!(
			person: people(:bob),
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		patch club_member_path(@club, member), params: {
			membership: {
				notes: "Updated medical clearance",
				person_attributes: {
					id: people(:bob).id,
					address: "Calle Olimpo 42"
				}
			}
		}

		assert_redirected_to club_member_path(@club, member, kind: :athlete)
		assert_equal "Updated medical clearance", member.reload.notes.to_plain_text
		assert_equal "Calle Olimpo 42", people(:bob).reload.address
	end

	test "PATCH update with status_only transitions membership status" do
		member = Membership.create!(
			person: people(:bob),
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		patch club_member_path(@club, member), params: {
			membership: {
				status: "suspended"
			}
		}

		assert_redirected_to club_member_path(@club, member, kind: :athlete)
		assert member.reload.status_suspended?
	end
end
