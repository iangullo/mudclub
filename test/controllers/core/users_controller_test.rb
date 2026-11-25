require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
	setup do
		@admin = users(:admin_user)
		@admin.update!(role: :admin)
		sign_in @admin
	end

	# ─── Authorization ───────────────────────────────────────

	test "unauthenticated visitor is denied access to users index" do
		sign_out @admin
		get users_path
		assert_redirected_to root_path
	end

	test "non-admin user is denied access to users index" do
		regular = users(:alice)
		sign_in regular

		get users_path
		assert_redirected_to root_path
	end

	# ─── Index & Show ────────────────────────────────────────

	test "GET index renders user list for system admin" do
		get users_path
		assert_response :success
	end

	test "GET show renders user profile" do
		get user_path(@admin)
		assert_response :success
	end

	# ─── Create (New Person, Existing Person, Missing Password, Merge Offer) ──

	test "POST create builds a new User and Person when valid params are submitted" do
		assert_difference [ -> { User.count }, -> { Person.count } ], 1 do
			post users_path, params: {
				user: {
					email: "coach.new@mudclub.test",
					password: "SecurePassword123!",
					password_confirmation: "SecurePassword123!",
					role: "user",
					locale: "es",
					person_attributes: {
						name: "Marta",
						surname: "Ramos",
						dni: "88888888M"
					}
				}
			}
		end

		created = User.find_by!(email: "coach.new@mudclub.test")
		assert_equal "Marta", created.person.name
		assert_equal "coach.new@mudclub.test", created.person.email
		assert_equal created.id, created.person.user_id
		assert_redirected_to user_path(created)
	end

	test "POST create links existing Person on exact identifier match" do
		standalone = Person.create!(
			name: "Javier",
			surname: "Ortega",
			dni: "99999999J",
			email: "javier@mudclub.test"
		)

		assert_no_difference -> { Person.count } do
			assert_difference -> { User.count }, 1 do
				post users_path, params: {
					user: {
						email: "javier@mudclub.test",
						password: "SecurePassword123!",
						password_confirmation: "SecurePassword123!",
						role: "user",
						person_attributes: {
							dni: standalone.dni,
							name: standalone.name,
							surname: standalone.surname
						}
					}
				}
			end
		end

		created = User.find_by!(email: "javier@mudclub.test")
		assert_equal standalone, created.person
		assert_equal created.id, standalone.reload.user_id
	end

	test "POST create rejects submission without password (422)" do
		assert_no_difference [ -> { User.count }, -> { Person.count } ] do
			post users_path, params: {
				user: {
					email: "nopass@mudclub.test",
					person_attributes: {
						name: "Sin",
						surname: "Clave"
					}
				}
			}
		end

		assert_response :unprocessable_entity
	end

	test "POST create renders merge offer (422) when dni matches a different name" do
		alice = people(:alice)

		assert_no_difference [ -> { User.count }, -> { Person.count } ] do
			post users_path, params: {
				user: {
					email: "conflict@mudclub.test",
					password: "SecurePassword123!",
					password_confirmation: "SecurePassword123!",
					person_attributes: {
						dni: alice.dni,
						name: "Wrong Name",
						surname: alice.surname
					}
				}
			}
		end

		assert_response :unprocessable_entity
	end

	# ─── Update & Email Sync ─────────────────────────────────

	test "PATCH update synchronizes User#email and canonical Person#email" do
		target_user = users(:alice)
		target_person = target_user.person

		patch user_path(target_user), params: {
			user: {
				email: "alice.updated@mudclub.test",
				locale: "en"
			}
		}

		assert_redirected_to user_path(target_user)
		assert_equal "alice.updated@mudclub.test", target_user.reload.email
		assert_equal "alice.updated@mudclub.test", target_person.reload.email
	end

	test "PATCH update offers merge (422) when new email conflicts with another Person" do
		target_user = users(:alice)
		bob = people(:bob)

		patch user_path(target_user), params: {
			user: {
				email: bob.email
			}
		}

		assert_response :unprocessable_entity
		assert_not_equal bob.email, target_user.reload.email
	end

	# ─── Actions Log & Destroy ───────────────────────────────

	test "GET actions and DELETE clear_actions manage user audit log" do
		get actions_user_path(@admin)
		assert_response :success

		get clear_actions_user_path(@admin)
		assert_redirected_to user_path(@admin, rdx: 1)
	end

	test "DELETE destroy removes user account" do
		target_user = users(:alice)

		assert_difference -> { User.count }, -1 do
			delete user_path(target_user)
		end

		assert_redirected_to users_path
	end
end
