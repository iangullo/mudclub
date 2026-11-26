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
	# ─── Identity Resolution & Merge Offers on Create ────────

	test "POST create normalizes login email casing/whitespace to link existing Person" do
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
						email: "  JAVIER@MudClub.TEST  ",
						password: "SecurePassword123!",
						password_confirmation: "SecurePassword123!",
						role: "user",
						person_attributes: {
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

	test "POST create offers merge (422 turbo_stream and 300 json) on probable/ambiguous match" do
		Person.create!(name: "Carlos", surname: "López")
		Person.create!(name: "Carlos", surname: "López")

		payload = {
			user: {
				email: "carlos.new@mudclub.test",
				password: "SecurePassword123!",
				password_confirmation: "SecurePassword123!",
				person_attributes: {
					name: "Carlos",
					surname: "López"
				}
			}
		}

		assert_no_difference [ -> { User.count }, -> { Person.count } ] do
			post users_path, params: payload, as: :turbo_stream
		end
		assert_response :unprocessable_entity
		assert_select "turbo-stream[action='replace'][target='modal']"

		assert_no_difference [ -> { User.count }, -> { Person.count } ] do
			post users_path, params: payload, as: :json
		end
		assert_response :multiple_choices
		assert_equal "offer_merge", response.parsed_body["status"]
	end

	test "POST create with person_merge=<canonical_id> links standalone Person and fills blank attributes" do
		standalone = Person.create!(
			name: "Elena",
			surname: "Torres",
			email: "elena@mudclub.test",
			address: nil
		)

		assert_no_difference -> { Person.count } do
			assert_difference -> { User.count }, 1 do
				post users_path, params: {
					user: {
						email: "elena@mudclub.test",
						password: "SecurePassword123!",
						password_confirmation: "SecurePassword123!",
						role: "user",
						person_merge: standalone.id.to_s,
						person_attributes: {
							name: "Elena",
							surname: "Torres",
							address: "Calle Mayor 12"
						}
					}
				}
			end
		end

		created = User.find_by!(email: "elena@mudclub.test")
		assert_equal standalone, created.person
		assert_equal created.id, standalone.reload.user_id
		assert_equal "Calle Mayor 12", standalone.address
	end

	test "POST create rejects creating a second User for a Person who already has an account" do
		alice_user = users(:alice)
		alice      = alice_user.person

		assert_no_difference [ -> { User.count }, -> { Person.count } ] do
			post users_path, params: {
				user: {
					email: "alice.second@mudclub.test",
					password: "SecurePassword123!",
					password_confirmation: "SecurePassword123!",
					role: "user",
					person_merge: alice.id.to_s,
					person_attributes: {
						name: alice.name,
						surname: alice.surname
					}
				}
			}
		end

		assert_response :unprocessable_entity
		assert_equal [ alice_user.id ], User.where(person_id: alice.id).pluck(:id)
	end

	# ─── Update & Duplicate Person Merging ───────────────────

	test "PATCH update offers merge (422 turbo_stream) when edited email collides with another Person" do
		target_user = users(:alice)
		bob         = people(:bob)

		patch user_path(target_user),
			params: {
				user: {
					email: bob.email
				}
			},
			as: :turbo_stream

		assert_response :unprocessable_entity
		assert_select "turbo-stream[action='replace'][target='modal']"
		assert_not_equal bob.email, target_user.reload.email
	end

	test "PATCH update with person_merge=<canonical_id> absorbs duplicate Person into canonical Person" do
		canonical = people(:bob)
		canonical.update!(address: nil)

		dup_person = Person.create!(
			name: "Bob",
			surname: "Duplicado",
			address: "Avenida Norte 8",
			email: "bob.dup@mudclub.test"
		)
		dup_user = User.create!(
			email: "bob.dup@mudclub.test",
			password: "SecurePassword123!",
			password_confirmation: "SecurePassword123!",
			person: dup_person,
			club_id: nil
		)

		patch user_path(dup_user), params: {
			user: {
				email: "bob.dup@mudclub.test",
				person_merge: canonical.id.to_s,
				person_attributes: {
					name: canonical.name,
					surname: canonical.surname
				}
			}
		}

		assert_redirected_to user_path(dup_user)
		assert dup_person.reload.merged?
		assert_equal canonical, dup_person.merged_into
		assert_equal canonical, dup_user.reload.person
		assert_equal "Avenida Norte 8", canonical.reload.address
	end

	test "PATCH update rolls back Person#absorb! when post-merge User validation fails" do
		canonical  = people(:bob)
		taken_user = users(:alice)

		dup_person = Person.create!(name: "Bob", surname: "Dup", email: "bob.rollback@mudclub.test")
		dup_user   = User.create!(
			email: "bob.rollback@mudclub.test",
			password: "SecurePassword123!",
			password_confirmation: "SecurePassword123!",
			person: dup_person,
			club_id: nil
		)

		patch user_path(dup_user), params: {
			user: {
				email: taken_user.email, # violates User email uniqueness
				person_merge: canonical.id.to_s,
				person_attributes: {
					name: canonical.name,
					surname: canonical.surname
				}
			}
		}

		assert_response :unprocessable_entity
		refute dup_person.reload.merged?, "absorb! must roll back if User save fails"
		assert_equal dup_person, dup_user.reload.person
	end

	# ─── GDPR / LOPD Anonymization ───────────────────────────
	test "PATCH anonymize allows user to anonymize their own account and signs them out" do
		sign_out @admin
		alice_user   = users(:alice)
		alice_person = alice_user.person
		sign_in alice_user

		patch anonymize_user_path(alice_user)

		assert_redirected_to root_path
		assert_not_nil alice_user.reload.anonymized_at
		assert_equal 0, alice_user.person_id
		assert_not_nil alice_person.reload.anonymized_at
	end

	test "PATCH anonymize denies non-admin user from anonymizing another user" do
		sign_in users(:alice)
		other_user = users(:admin_user)

		patch anonymize_user_path(other_user)

		assert_redirected_to root_path
		assert_nil other_user.reload.anonymized_at
	end
	# In UsersControllerTest
	test "GET show renders anonymize button with confirmation for own profile or admin" do
		sign_out @admin
		alice_user = users(:alice)
		sign_in alice_user

		get user_path(alice_user)

		assert_response :success
		assert_select "a.anonymize-btn[href='#{anonymize_user_path(alice_user)}'][data-turbo-method='patch'][data-turbo-confirm]"
	end

	test "GET show hides anonymize button when user is already anonymized" do
		target = users(:alice)
		target.anonymize!

		get user_path(target)

		assert_response :success
		assert_select "a.anonymize-btn", count: 0
	end
end
