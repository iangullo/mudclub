require "test_helper"

class PersonFormFlowTest < ActiveSupport::TestCase
	# ─── prepare_person & resolve_person ─────────────────────

	test "prepare_person reuses existing Person on exact identifier match and fills blank fields" do
		alice = people(:alice)
		alice.update!(address: nil)

		membership = Membership.new(
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		resolution = membership.prepare_person({
			person_attributes: {
				dni: alice.dni,
				name: alice.name,
				surname: alice.surname,
				address: "Avenida del Deporte 10"
			}
		})

		assert resolution.ok?
		assert_equal alice, membership.person
		assert_equal "Avenida del Deporte 10", membership.person.address
	end

	test "prepare_person returns :conflict when strong identifier matches a different name" do
		alice = people(:alice)
		membership = Membership.new(
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		resolution = membership.prepare_person({
			person_attributes: {
				dni: alice.dni,
				name: "Wrong Name",
				surname: alice.surname
			}
		})

		assert resolution.conflict?
		assert_equal alice, resolution.conflicts[:name]
	end

	test "prepare_person shifts nested avatar onto the PersonBearing record and bubbles up on save" do
		bob = people(:bob)
		membership = Membership.new(
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		blob = ActiveStorage::Blob.create_and_upload!(
			io: StringIO.new("\x89PNG\r\n\x1A\nform-avatar-#{SecureRandom.hex(4)}"),
			filename: "form_upload.png",
			content_type: "image/png"
		)

		attrs = {
			person_attributes: {
				dni: bob.dni,
				name: bob.name,
				surname: bob.surname,
				avatar: blob
			}
		}

		resolution = membership.prepare_person(attrs)
		assert resolution.ok?
		assert_equal blob, attrs[:avatar], "avatar must be shifted to top-level attrs"
		assert_nil attrs[:person_attributes][:avatar]

		membership.avatar.attach(attrs[:avatar])
		membership.save!

		assert_equal blob.id, membership.reload.avatar.blob_id
		assert_equal blob.id, bob.reload.avatar.blob_id
	end

	# ─── rebuild_relationships ───────────────────────────────

	test "rebuild processes relationships_attributes including _destroy flags" do
		minor  = people(:bob)
		parent = people(:alice)
		rel    = Relationship.create!(person: minor, related_person: parent, kind: :parent)

		minor.rebuild({
			relationships_attributes: {
				"0" => { id: rel.id.to_s, _destroy: "1" }
			}
		})

		refute Relationship.exists?(rel.id)
	end

	# ─── Participatory shared helpers (all_pics?, p_email, p_phone) ──

	test "all_pics? requires id_front, id_back, and either participation or person avatar" do
		alice = people(:alice)
		membership = Membership.create!(
			person: alice,
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		refute membership.all_pics?

		attach_test_image(alice, :id_front, filename: "front.png")
		attach_test_image(alice, :id_back, filename: "back.png")
		refute membership.all_pics?, "still missing an avatar"

		attach_test_image(membership, :avatar, filename: "member.png")
		assert membership.all_pics?
	end

	test "p_email and p_phone return guardian contacts for minors and self contacts for adults" do
		parent = people(:alice)
		minor  = people(:bob)
		minor.update!(birthday: 12.years.ago.to_date, email: nil, phone: nil)
		Relationship.create!(person: minor, related_person: parent, kind: :parent)

		membership = Membership.create!(
			person: minor,
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		assert_equal parent.email, membership.p_email
		assert_equal parent.phone, membership.p_phone

		# Once adult, returns own contact details
		minor.update!(birthday: 20.years.ago.to_date, email: "bob.adult@mudclub.test", phone: "+34600000099")
		assert_equal "bob.adult@mudclub.test", membership.reload.p_email
		assert_equal "+34600000099", membership.p_phone
	end

	test "p_email and p_phone handle minors with guardian-only, combined, and adult contacts" do
		parent = people(:alice)
		minor  = people(:bob)
		minor.update!(birthday: 12.years.ago.to_date, email: nil, phone: nil)
		Relationship.create!(person: minor, related_person: parent, kind: :parent)

		membership = Membership.create!(
			person: minor,
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		# 1. Minor with no personal email/phone -> guardian contact only
		assert_equal parent.email, membership.p_email
		assert_equal parent.phone, membership.p_phone

		# 2. Minor with personal email/phone -> guardian + own joined with newline
		minor.update!(email: "bob.kid@mudclub.test", phone: "+34600000088")
		assert_equal "#{parent.email}\nbob.kid@mudclub.test", membership.reload.p_email
		assert_equal "#{parent.phone}\n+34600000088", membership.p_phone

		# 3. Adult -> own contact only (excludes guardians)
		minor.update!(birthday: 20.years.ago.to_date, email: "bob.adult@mudclub.test", phone: "+34600000099")
		assert_equal "bob.adult@mudclub.test", membership.reload.p_email
		assert_equal "+34600000099", membership.p_phone
	end
end
