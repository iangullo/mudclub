require "test_helper"

class PersonTest < ActiveSupport::TestCase
	# ─── Normalization & Validations ─────────────────────────

	test "normalizes and titleizes fields before validation and save" do
		person = Person.create!(
			name: "  maría josé  ",
			surname: "  garcía lópez  ",
			nick: "  majo  ",
			dni: " 12345678z ",
			email: "  Maria@MudClub.TEST  ",
			phone: " +34 600 111 222 ",
			address: "  Calle Mayor 1  "
		)

		assert_equal "María José", person.name
		assert_equal "García López", person.surname
		assert_equal "majo", person.nick
		assert_equal "12345678Z", person.dni
		assert_equal "maria@mudclub.test", person.email
		assert_equal "+34 600 111 222", person.phone
		assert_equal "Calle Mayor 1", person.address
	end

	test "validates presence of name and surname and uniqueness of dni, email, phone" do
		invalid = Person.new(name: "", surname: "")
		refute invalid.valid?
		assert_includes invalid.errors[:name], I18n.t("errors.messages.blank")
		assert_includes invalid.errors[:surname], I18n.t("errors.messages.blank")

		alice = people(:alice)
		dup = Person.new(
			name: "Clone",
			surname: "User",
			dni: alice.dni,
			email: alice.email,
			phone: alice.phone
		)
		refute dup.valid?
		assert dup.errors[:dni].any?
		assert dup.errors[:email].any?
		assert dup.errors[:phone].any?
	end

	# ─── Scopes & Placeholders ───────────────────────────────

	test "placeholder? and canonical? distinguish id 0 and merged records" do
		placeholder = Person.find_or_create_by!(id: 0) { |p| p.name = "Club"; p.surname = "System" }
		alice = people(:alice)
		bob   = people(:bob)

		assert placeholder.placeholder?
		refute placeholder.canonical?

		assert alice.canonical?
		refute alice.merged?

		alice.update_columns(merged_into_id: bob.id)
		assert alice.merged?
		refute alice.canonical?
		assert_equal bob, alice.canonical
	end

	test "cannot merge a person into themselves" do
		alice = people(:alice)
		alice.merged_into = alice
		refute alice.valid?
		assert_includes alice.errors[:merged_into], I18n.t("errors.messages.invalid")
	end

	# ─── Age & Legal Guardians ───────────────────────────────

	test "age and minor? calculate accurately around birthday" do
		person = people(:bob)

		person.birthday = 18.years.ago.to_date
		assert_equal 18, person.age
		refute person.minor?
		assert_equal [ person ], person.responsible_adults

		person.birthday = 18.years.ago.to_date + 1.day
		assert_equal 17, person.age
		assert person.minor?
	end

	test "guardians, dependents, and responsible_adults traverse a single parent relationship" do
		parent = people(:alice)
		minor  = people(:bob)
		minor.update!(birthday: 12.years.ago.to_date)

		# A single :parent record links parent (person) -> minor (related_person)
		Relationship.create!(person: minor, related_person: parent, kind: :parent)

		assert parent.is_responsible_adult?
		assert_includes parent.dependents, minor

		assert minor.has_guardians?
		assert_includes minor.guardians, parent
		assert_includes minor.responsible_adults, parent
	end

	test "relationship normalize! flips non-selectable inverse kinds into canonical direction" do
		parent = people(:alice)
		minor  = people(:bob)

		rel = Relationship.new(person: minor, related_person: parent, kind: :child)
		rel.normalize!

		assert_equal parent, rel.person
		assert_equal minor, rel.related_person
		assert_equal :parent, rel.kind.to_sym
	end

	test "Relationship#rebuild resolves existing person or builds new person from nested attributes" do
		minor = people(:bob)
		existing_parent = people(:alice)

		# 1. Exact match by strong identifier (email) reuses existing Person
		rel_existing = Relationship.new
		rel_existing.rebuild(minor, {
			kind: :parent,
			related_person_attributes: {
				email: existing_parent.email,
				name: "Alice",
				surname: "Admin"
			}
		})

		assert rel_existing.valid?, rel_existing.errors.full_messages.to_sentence
		assert_equal existing_parent, rel_existing.related_person

		# 2. Unknown person builds a new Person record
		rel_new = Relationship.new
		rel_new.rebuild(minor, {
			kind: :parent,
			related_person_attributes: {
				name: "Elena",
				surname: "Guardian",
				email: "elena.guardian@mudclub.test"
			}
		})

		assert rel_new.valid?, rel_new.errors.full_messages.to_sentence
		assert rel_new.related_person.new_record?
		assert_equal "Elena", rel_new.related_person.name
	end

	test "rebuild processes relationships_attributes including _destroy flags" do
		minor = people(:bob)
		parent = people(:alice)
		rel = Relationship.create!(person: parent, related_person: minor, kind: :parent)

		parent.rebuild({
			relationships_attributes: {
				"0" => { id: rel.id.to_s, _destroy: "1" }
			}
		})

		refute Relationship.exists?(rel.id)
	end

	# ─── Identity Resolution & PersonResolution ──────────────

	test "resolve finds exact match by strong identifier and tolerates diacritics in mismatches" do
		alice = people(:alice)
		alice.update!(name: "José María", surname: "García")

		res_dni = Person.resolve({ dni: " 11111111a " })
		assert res_dni.exact?
		assert res_dni.ok?
		assert_equal alice, res_dni.person
		assert_equal :dni, res_dni.matched_by

		# Accent-insensitive and case-insensitive match via PersonResolution
		assert res_dni.matches?(name: "jose maria", surname: "GARCIA")
		assert_equal [ :name ], res_dni.mismatches_against(name: "Pedro", surname: "García")
	end

	test "resolve excludes specified person and falls back to probable name match" do
		alice = people(:alice)

		excluded = Person.resolve({ dni: alice.dni }, exclude: alice)
		assert excluded.none?

		probable = Person.resolve({ name: "Alice", surname: "Admin" })
		assert probable.probable?
		assert probable.ambiguous?
		assert_equal alice, probable.person
		assert_equal :name, probable.matched_by
	end

	test "conflicts detects duplicate unique identifiers against other current people" do
		alice = people(:alice)
		bob   = people(:bob)

		bob.email = alice.email
		conflicts = bob.conflicts
		assert_equal alice, conflicts[:email]
	end

	# ─── absorb! (Duplicate Merging) ─────────────────────────

	test "absorb! raises ArgumentError when absorbing self" do
		alice = people(:alice)
		assert_raises(ArgumentError) { alice.absorb!(alice) }
	end

	test "absorb! fills blank scalar attributes without overwriting existing ones" do
		target = people(:alice)
		target.update!(nick: nil, address: nil, birthday: nil)

		duplicate = Person.create!(
			name: "Alicia",
			surname: "Different",
			nick: "ali_dup",
			address: "Calle Nueva 5",
			birthday: Date.new(1995, 5, 10),
			dni: "99999999Z",
			email: "dup@mudclub.test",
			phone: "+34699999999"
		)

		target.absorb!(duplicate)
		target.reload

		assert_equal "Alice", target.name
		assert_equal "11111111A", target.dni
		assert_equal "alice@mudclub.test", target.email

		assert_equal "ali_dup", target.nick
		assert_equal "Calle Nueva 5", target.address
		assert_equal Date.new(1995, 5, 10), target.birthday
	end

	test "absorb! transfers missing attachments while preserving target attachments" do
		target    = people(:alice)
		duplicate = people(:bob)

		target_avatar = attach_test_image(target, :avatar, filename: "alice.png")
		dup_avatar    = attach_test_image(duplicate, :avatar, filename: "bob.png")
		dup_id_front  = attach_test_image(duplicate, :id_front, filename: "bob_front.png")

		target.absorb!(duplicate)
		target.reload

		assert_equal target_avatar.id, target.avatar.blob_id
		refute_equal dup_avatar.id, target.avatar.blob_id

		assert target.id_front.attached?
		assert_equal dup_id_front.id, target.id_front.blob_id
	end

	test "absorb! reassigns user, merges matching memberships, and moves distinct memberships" do
		club      = clubs(:test_club)
		target    = people(:alice)
		duplicate = people(:bob)

		user = users(:admin_user)
		user.update!(person: duplicate)

		m_target = Membership.create!(person: target, club:, kind: :athlete, status: :active, joined_on: Date.new(2025, 1, 1))
		m_dup    = Membership.create!(person: duplicate, club:, kind: :athlete, status: :active, joined_on: Date.new(2024, 1, 1))
		m_coach  = Membership.create!(person: duplicate, club:, kind: :coach, status: :active, joined_on: Date.new(2024, 6, 1))

		target.absorb!(duplicate)

		assert_equal target.id, user.reload.person_id
		assert_equal Date.new(2024, 1, 1), m_target.reload.joined_on
		assert_nil Membership.find_by(id: m_dup.id)
		assert_equal target.id, m_coach.reload.person_id
	end

	test "absorb! deduplicates identical relationships and moves distinct ones" do
		target    = people(:alice)
		duplicate = people(:bob)
		third     = Person.create!(name: "Charlie", surname: "Third")
		fourth    = Person.create!(name: "Dana", surname: "Fourth")

		rel_target_same = Relationship.create!(person: target, related_person: third, kind: :parent)
		rel_dup_same    = Relationship.create!(person: duplicate, related_person: third, kind: :parent)
		rel_dup_unique  = Relationship.create!(person: duplicate, related_person: fourth, kind: :parent)

		target.absorb!(duplicate)

		assert Relationship.exists?(rel_target_same.id)
		refute Relationship.exists?(rel_dup_same.id)
		assert_equal target.id, rel_dup_unique.reload.person_id
	end

	test "absorb! marks duplicate as merged and clears its unique identifiers" do
		target    = people(:alice)
		duplicate = people(:bob)

		target.absorb!(duplicate)
		duplicate.reload

		assert_equal target.id, duplicate.merged_into_id
		assert_equal "[MERGED]", duplicate.nick
		assert_nil duplicate.dni
		assert_nil duplicate.email
		assert_nil duplicate.phone
		refute_includes Person.current, duplicate
	end

	test "absorb! transfers and deduplicates inverse_relationships when merging duplicate minors" do
		target_minor = people(:bob)
		target_minor.update!(birthday: 12.years.ago.to_date)

		dup_minor = Person.create!(
			name: "Bob",
			surname: "Duplicate",
			birthday: 12.years.ago.to_date
		)

		shared_parent = people(:alice)
		second_parent = Person.create!(name: "Carlos", surname: "Parent")

		# Both target and duplicate have a guardian relationship from shared_parent -> should deduplicate
		rel_target_shared = Relationship.create!(person: target_minor, related_person: shared_parent, kind: :parent)
		rel_dup_shared    = Relationship.create!(person: dup_minor, related_person: shared_parent, kind: :parent)

		# Duplicate also has a guardian relationship from second_parent -> should transfer to target_minor
		rel_dup_second    = Relationship.create!(person: dup_minor, related_person: second_parent, kind: :parent)

		# Self-referential edge case: target_minor was linked to dup_minor -> must be destroyed, not self-linked
		rel_self_edge     = Relationship.create!(person: dup_minor, related_person: target_minor, kind: :sibling)

		target_minor.absorb!(dup_minor)

		assert Relationship.exists?(rel_target_shared.id)
		refute Relationship.exists?(rel_dup_shared.id), "duplicate inverse relationship must be destroyed"
		refute Relationship.exists?(rel_self_edge.id), "self-referential inverse relationship must be destroyed"

		assert_equal target_minor.id, rel_dup_second.reload.person_id
		assert_equal [ shared_parent.id, second_parent.id ].sort, target_minor.guardians.pluck(:id).sort
	end

	# ─── GDPR / LOPD Anonymization ───────────────────────────

	test "anonymize! scrubs PII and purges shared and distinct blobs across entire object graph" do
		person = people(:alice)
		user   = users(:admin_user)
		user.update_columns(person_id: person.id)
		person.update_columns(user_id: user.id)
		user.reload
		person.reload

		membership = Membership.create!(
			person: person,
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		assignment = Assignment.create!(
			membership: membership,
			team: teams(:senior_a),
			kind: :athlete,
			status: :active,
			starts_on: Date.current
		)

		doc_blob = ActiveStorage::Blob.create_and_upload!(
			io: StringIO.new("%PDF-1.4 fake-contract-#{SecureRandom.hex(4)}"),
			filename: "contract.pdf",
			content_type: "application/pdf"
		)
		doc = Document.new(person: person, kind: :other)
		doc.file.attach(doc_blob)
		doc.save!

		shared_blob   = attach_test_image(assignment, filename: "shared.png")
		user_blob = ActiveStorage::Blob.create_and_upload!(
			io: StringIO.new("\x89PNG\r\n\x1A\nuser-only-#{SecureRandom.hex(4)}"),
			filename: "user_only.png",
			content_type: "image/png"
		)
		ActiveStorage::Attachment.create!(
			name: "avatar",
			record_type: "User",
			record_id: user.id,
			blob_id: user_blob.id
		)
		user.reload
		assert user.avatar.attached?, "precondition: user avatar must be attached before anonymize!"
		id_front_blob = attach_test_image(person, :id_front, filename: "dni_front.png")
		id_back_blob  = attach_test_image(person, :id_back, filename: "dni_back.png")

		all_blob_ids = [
			shared_blob.id,
			user_blob.id,
			id_front_blob.id,
			id_back_blob.id,
			doc_blob.id
		]

		assert_equal 5, ActiveStorage::Blob.where(id: all_blob_ids).count

		person.anonymize!
		person.reload

		assert_not_nil person.anonymized_at
		assert_nil person.dni
		assert_nil person.email
		assert_nil person.phone
		assert_nil person.address
		assert_nil person.birthday
		assert_nil person.user_id

		user.reload
		assert_not_nil user.anonymized_at
		assert_equal 0, user.person_id

		refute person.avatar.attached?
		refute person.id_front.attached?
		refute person.id_back.attached?
		refute user.avatar.attached?
		refute membership.reload.avatar.attached?
		refute assignment.reload.avatar.attached?
		assert_equal 0, person.documents.count
		remaining = ActiveStorage::Blob.where(id: all_blob_ids).pluck(:filename)
		assert_equal [], remaining, "all ActiveStorage blobs must be purged, remaining: #{remaining.inspect}"
	end

	test "anonymize! is idempotent" do
		person = people(:alice)
		person.anonymize!
		first_timestamp = person.reload.anonymized_at
		first_name      = person.name
		person.anonymize!
		person.reload
		assert_equal first_timestamp, person.anonymized_at
		assert_equal first_name, person.name
	end
end
