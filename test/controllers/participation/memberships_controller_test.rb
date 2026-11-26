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
	# ─── Identity Resolution Edge Cases on Create ────────────

	test "POST create normalizes email casing/whitespace and DNI spacing to match existing Person" do
		alice = people(:alice)

		assert_no_difference -> { Person.count } do
			assert_difference -> { Membership.count }, 1 do
				post club_members_path(@club), params: {
					kind: "athletes",
					membership: {
						kind: "athlete",
						person_attributes: {
							email: "  #{alice.email.upcase}  ",
							name: alice.name,
							surname: alice.surname
						}
					}
				}
			end
		end

		assert_equal alice, Membership.order(:created_at).last.person
	end

	test "POST create offers merge (422) on probable name match (accent-insensitive)" do
		alice = people(:alice)
		alice.update!(name: "José María", surname: "García")

		assert_no_difference [ -> { Person.count }, -> { Membership.count } ] do
			post club_members_path(@club), params: {
				kind: "athletes",
				membership: {
					kind: "athlete",
					person_attributes: {
						name: "jose maria",
						surname: "GARCIA"
					}
				}
			}
		end

		assert_response :unprocessable_entity
		assert_select "form" # renders shared/merge modal
	end

	test "POST create offers merge (422) when multiple people share the same name (ambiguous)" do
		Person.create!(name: "Carlos", surname: "López")
		Person.create!(name: "Carlos", surname: "López")

		assert_no_difference [ -> { Person.count }, -> { Membership.count } ] do
			post club_members_path(@club), params: {
				kind: "athletes",
				membership: {
					kind: "athlete",
					person_attributes: {
						name: "Carlos",
						surname: "López"
					}
				}
			}
		end

		assert_response :unprocessable_entity
	end

	test "POST create ignores already-merged Person records during resolution" do
		target    = people(:alice)
		duplicate = Person.create!(name: "Ghost", surname: "Duplicate", dni: "44444444G")
		target.absorb!(duplicate) # clears duplicate.dni and sets merged_into_id

		assert_difference [ -> { Person.count }, -> { Membership.count } ], 1 do
			post club_members_path(@club), params: {
				kind: "athletes",
				membership: {
					kind: "athlete",
					person_attributes: {
						name: "New",
						surname: "Athlete",
						dni: "44444444G"
					}
				}
			}
		end

		assert_response :redirect
	end

	# ─── Merge Resolution Execution (person_merge param) ─────

	test "POST create with person_merge=__new__ creates a distinct Person despite name collision" do
		existing = Person.create!(name: "Carlos", surname: "López", email: "carlos1@mudclub.test")

		assert_difference [ -> { Person.count }, -> { Membership.count } ], 1 do
			post club_members_path(@club), params: {
				kind: "athletes",
				membership: {
					kind: "athlete",
					person_merge: "__new__",
					person_attributes: {
						name: "Carlos",
						surname: "López",
						email: "carlos2@mudclub.test"
					}
				}
			}
		end

		created_person = Membership.order(:created_at).last.person
		assert_not_equal existing.id, created_person.id
		assert_equal "carlos2@mudclub.test", created_person.email
		assert_redirected_to club_members_path(kind: :athlete)
	end

	test "POST create with person_merge=<canonical_id> links existing Person and fills blank attributes" do
		canonical = people(:alice)
		canonical.update!(address: nil, birthday: nil)

		assert_no_difference -> { Person.count } do
			assert_difference -> { Membership.count }, 1 do
				post club_members_path(@club), params: {
					kind: "athletes",
					membership: {
						kind: "athlete",
						person_merge: canonical.id.to_s,
						person_attributes: {
							name: canonical.name,
							surname: canonical.surname,
							address: "Avenida del Deporte 10",
							birthday: "2000-05-15"
						}
					}
				}
			end
		end

		created = Membership.order(:created_at).last
		assert_equal canonical, created.person
		assert_equal "Avenida del Deporte 10", canonical.reload.address
		assert_equal Date.new(2000, 5, 15), canonical.birthday
	end

	test "POST create with person_merge=<canonical_id> still fails (422) if new unique identifier conflicts with a third Person" do
		canonical = people(:alice)
		bob       = people(:bob)

		assert_no_difference [ -> { Person.count }, -> { Membership.count } ] do
			post club_members_path(@club), params: {
				kind: "athletes",
				membership: {
					kind: "athlete",
					person_merge: canonical.id.to_s,
					person_attributes: {
						name: canonical.name,
						surname: canonical.surname,
						email: bob.email # belongs to Bob, not Alice
					}
				}
			}
		end

		assert_response :unprocessable_entity
		assert_not_equal bob.email, canonical.reload.email
	end

	# ─── Update & Duplicate Person Merging ───────────────────

	test "PATCH update offers merge (422) when edited email or DNI collides with another Person" do
		alice = people(:alice)
		bob   = people(:bob)
		member = Membership.create!(
			person: bob,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		patch club_member_path(@club, member), params: {
			membership: {
				person_attributes: {
					id: bob.id,
					email: alice.email
				}
			}
		}

		assert_response :unprocessable_entity
		assert_not_equal alice.email, bob.reload.email
	end

	test "PATCH update with person_merge=__keep__ saves changes when probable match was dismissed" do
		bob = people(:bob)
		Person.create!(name: bob.name, surname: bob.surname) # creates probable collision
		member = Membership.create!(
			person: bob,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		patch club_member_path(@club, member), params: {
			membership: {
				person_merge: "__keep__",
				person_attributes: {
					id: bob.id,
					name: bob.name,
					surname: bob.surname,
					address: "Calle Confirmada 9"
				}
			}
		}

		assert_redirected_to club_member_path(@club, member, kind: :athlete)
		assert_equal "Calle Confirmada 9", bob.reload.address
	end

	test "PATCH update with person_merge=<canonical_id> absorbs duplicate Person and reassigns membership" do
		canonical = people(:alice)
		canonical.update!(address: nil)

		duplicate = Person.create!(
			name: "Alice",
			surname: "Duplicada",
			address: "Calle Absorción 7",
			email: "alice.dup@mudclub.test"
		)
		dup_member = Membership.create!(
			person: duplicate,
			club: @club,
			kind: :coach,
			status: :active,
			joined_on: Date.current
		)

		patch club_member_path(@club, dup_member), params: {
			membership: {
				person_merge: canonical.id.to_s,
				person_attributes: {
					name: "Alice",
					surname: "Admin"
				}
			}
		}

		assert_redirected_to club_member_path(@club, dup_member, kind: :coach)
		assert_equal canonical, dup_member.reload.person
		assert_equal "Calle Absorción 7", canonical.reload.address
		assert duplicate.reload.merged?
		assert_equal canonical, duplicate.merged_into
		assert_nil duplicate.email
	end

	test "PATCH update with person_merge=<canonical_id> consolidates memberships when canonical already has same club+kind membership" do
		canonical = people(:alice)
		duplicate = people(:bob)
		team      = teams(:senior_a)

		canonical_member = Membership.create!(
			person: canonical,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.new(2025, 9, 1)
		)
		dup_member = Membership.create!(
			person: duplicate,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.new(2024, 9, 1)
		)
		dup_assignment = Assignment.create!(
			membership: dup_member,
			team: team,
			kind: :athlete,
			status: :active,
			starts_on: Date.new(2024, 9, 1),
			number: "10"
		)

		patch club_member_path(@club, dup_member), params: {
			membership: {
				person_merge: canonical.id.to_s,
				person_attributes: {
					name: canonical.name,
					surname: canonical.surname
				}
			}
		}

		# Duplicate person and duplicate membership are consolidated into canonical
		assert duplicate.reload.merged?
		assert_nil Membership.find_by(id: dup_member.id)
		assert_equal Date.new(2024, 9, 1), canonical_member.reload.joined_on
		assert_equal canonical_member, dup_assignment.reload.membership
	end
	# ─── Turbo Stream & JSON Merge Flows ─────────────────────

	test "POST create returns turbo_stream replacing modal (422) on merge offer" do
		alice = people(:alice)

		assert_no_difference [ -> { Person.count }, -> { Membership.count } ] do
			post club_members_path(@club),
				params: {
					kind: "athletes",
					membership: {
						kind: "athlete",
						person_attributes: {
							dni: alice.dni,
							name: "Wrong Name",
							surname: alice.surname
						}
					}
				},
				as: :turbo_stream
		end

		assert_response :unprocessable_entity
		assert_equal "text/vnd.turbo-stream.html", response.media_type
		assert_select "turbo-stream[action='replace'][target='modal']"
	end

	test "POST create returns JSON 300 multiple_choices with offer_merge status on conflict" do
		alice = people(:alice)

		assert_no_difference [ -> { Person.count }, -> { Membership.count } ] do
			post club_members_path(@club),
				params: {
					kind: "athletes",
					membership: {
						kind: "athlete",
						person_attributes: {
							dni: alice.dni,
							name: "Wrong Name",
							surname: alice.surname
						}
					}
				},
				as: :json
		end

		assert_response :multiple_choices
		assert_equal "offer_merge", response.parsed_body["status"]
	end

	test "PATCH update returns turbo_stream replacing modal (422) when edited identifier collides" do
		alice  = people(:alice)
		bob    = people(:bob)
		member = Membership.create!(
			person: bob,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		patch club_member_path(@club, member),
			params: {
				membership: {
					person_attributes: {
						id: bob.id,
						email: alice.email
					}
				}
			},
			as: :turbo_stream

		assert_response :unprocessable_entity
		assert_select "turbo-stream[action='replace'][target='modal']"
	end

	test "PATCH update returns JSON 300 multiple_choices when edited identifier collides" do
		alice  = people(:alice)
		bob    = people(:bob)
		member = Membership.create!(
			person: bob,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		patch club_member_path(@club, member),
			params: {
				membership: {
					person_attributes: {
						id: bob.id,
						dni: alice.dni
					}
				}
			},
			as: :json

		assert_response :multiple_choices
		assert_equal "offer_merge", response.parsed_body["status"]
	end

	test "PATCH update with person_merge via turbo_stream consolidates memberships and redirects to canonical member" do
		canonical = people(:alice)
		duplicate = people(:bob)

		canonical_member = Membership.create!(
			person: canonical,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.new(2025, 9, 1)
		)
		dup_member = Membership.create!(
			person: duplicate,
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.new(2024, 9, 1)
		)

		patch club_member_path(@club, dup_member),
			params: {
				membership: {
					person_merge: canonical.id.to_s,
					notes: "Consolidated via Turbo",
					person_attributes: {
						name: canonical.name,
						surname: canonical.surname
					}
				}
			},
			as: :turbo_stream

		assert_redirected_to club_member_path(@club, canonical_member, kind: :athlete)
		assert_equal "Consolidated via Turbo", canonical_member.reload.notes.to_plain_text
		assert_equal Date.new(2024, 9, 1), canonical_member.joined_on
		assert duplicate.reload.merged?
	end

	test "PATCH update rolls back Person#absorb! when post-merge attributes fail validation" do
		canonical = people(:alice)
		duplicate = people(:bob)
		third     = Person.create!(name: "Third", surname: "Person", email: "taken@mudclub.test")

		dup_member = Membership.create!(
			person: duplicate,
			club: @club,
			kind: :coach,
			status: :active,
			joined_on: Date.current
		)

		patch club_member_path(@club, dup_member),
			params: {
				membership: {
					person_merge: canonical.id.to_s,
					person_attributes: {
						name: canonical.name,
						surname: canonical.surname,
						email: third.email # invalid uniqueness conflict on canonical
					}
				}
			},
			as: :turbo_stream

		assert_response :unprocessable_entity
		refute duplicate.reload.merged?, "absorb! must roll back if post-merge save fails"
		assert_equal duplicate, dup_member.reload.person
	end

	# ─── GDPR / LOPD Anonymization ───────────────────────────

	test "PATCH anonymize scrubs terminated membership, assignment notes/avatars, and person PII" do
		person = Person.create!(name: "Laura", surname: "Vega", dni: "66666666L", email: "laura@mudclub.test")
		member = Membership.create!(
			person: person,
			club: @club,
			kind: :athlete,
			status: :terminated,
			joined_on: 1.year.ago.to_date,
			left_on: Date.current,
			notes: "Member medical note"
		)
		assignment = Assignment.create!(
			membership: member,
			team: teams(:senior_a),
			kind: :athlete,
			status: :terminated,
			starts_on: 1.year.ago.to_date,
			ends_on: Date.current,
			notes: "Coach evaluation note"
		)
		blob = attach_test_image(assignment, filename: "assignment_pic.png")

		patch anonymize_club_member_path(@club, member)

		assert_redirected_to club_members_path(@club, kind: :athlete)
		reloaded_member     = Membership.find(member.id)
		reloaded_assignment = Assignment.find(assignment.id)

		assert_equal "archived", reloaded_member.status
		assert_empty reloaded_member.notes.to_plain_text
		assert_empty reloaded_assignment.notes.to_plain_text
		refute reloaded_assignment.avatar.attached?
		assert_equal 0, ActiveStorage::Blob.where(id: blob.id).count
		assert_not_nil person.reload.anonymized_at
		assert_nil person.dni
		assert_nil person.email
	end

	test "PATCH anonymize rejects active (non-terminated) membership" do
		member = Membership.create!(
			person: people(:bob),
			club: @club,
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		patch anonymize_club_member_path(@club, member)

		assert_redirected_to club_member_path(@club, member, kind: :athlete)
		assert_equal "active", member.reload.status
		assert_nil people(:bob).reload.anonymized_at
	end

	test "PATCH anonymize allows club manager when person has no current memberships in other clubs" do
		manager_user   = users(:alice)
		manager_person = manager_user.person
		manager_member = Membership.create!(
			person: manager_person,
			club: @club,
			kind: :volunteer,
			status: :active,
			joined_on: Date.current
		)
		Assignment.create!(
			membership: manager_member,
			kind: :club_manager,
			status: :active,
			starts_on: Date.current
		)
		sign_in manager_user

		target_person = Person.create!(name: "Solo", surname: "Member", dni: "33333333S")
		target_member = Membership.create!(
			person: target_person,
			club: @club,
			kind: :athlete,
			status: :terminated,
			joined_on: 1.year.ago.to_date,
			left_on: Date.current
		)

		patch anonymize_club_member_path(@club, target_member)

		assert_redirected_to club_members_path(@club, kind: :athlete)
		assert_equal "archived", target_member.reload.status
		assert_not_nil target_person.reload.anonymized_at
	end

	test "PATCH anonymize denies club manager when person still holds an active membership in another club" do
		manager_user   = users(:alice)
		manager_person = manager_user.person
		manager_member = Membership.create!(
			person: manager_person,
			club: @club,
			kind: :volunteer,
			status: :active,
			joined_on: Date.current
		)
		Assignment.create!(
			membership: manager_member,
			kind: :club_manager,
			status: :active,
			starts_on: Date.current
		)
		sign_in manager_user

		shared_person = Person.create!(name: "Multi", surname: "Club", dni: "22222222M")
		terminated_here = Membership.create!(
			person: shared_person,
			club: @club,
			kind: :athlete,
			status: :terminated,
			joined_on: 1.year.ago.to_date,
			left_on: Date.current
		)
		Membership.create!(
			person: shared_person,
			club: clubs(:north),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		patch anonymize_club_member_path(@club, terminated_here)

		assert_redirected_to root_path
		assert_equal "terminated", terminated_here.reload.status
		assert_nil shared_person.reload.anonymized_at
	end
end
