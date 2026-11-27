require "test_helper"

class PropagatableAvatarTest < ActiveSupport::TestCase
	# ─── Contract enforcement ────────────────────────────────

	test "raises NotImplementedError when avatar_propagation_target is not defined" do
		incomplete_class = Class.new(ApplicationRecord) do
			self.table_name = "memberships"
			include PropagatableAvatar
		end

		record = incomplete_class.new
		assert_raises(NotImplementedError) do
			record.send(:avatar_propagation_target)
		end
	end

	# ─── Creation inheritance ────────────────────────────────

	test "inherits source avatar blob on create when record has no avatar" do
		person = Person.create!(name: "Clara", surname: "Soto")
		blob   = attach_test_image(person, filename: "clara.png")

		member = Membership.create!(
			person: person,
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		assert member.avatar.attached?
		assert_equal blob.id, member.avatar.blob_id
	end

	test "does not overwrite an explicit avatar attached before create" do
		person = Person.create!(name: "Clara", surname: "Soto")
		attach_test_image(person, filename: "clara_parent.png")

		member = Membership.new(
			person: person,
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)
		own_blob = attach_test_image(member, filename: "clara_member.png")
		member.save!

		assert_equal own_blob.id, member.reload.avatar.blob_id
	end

	# ─── Upward propagation ──────────────────────────────────

	test "propagates avatar upward to target on create and update" do
		person = Person.create!(name: "Diego", surname: "Ruiz")
		member = Membership.create!(
			person: person,
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)

		first_blob = attach_test_image(member, filename: "diego_v1.png")
		assert_equal first_blob.id, person.reload.avatar.blob_id

		second_blob = attach_test_image(member, filename: "diego_v2.png")
		assert_equal second_blob.id, person.reload.avatar.blob_id
	end

	test "does not propagate upward when target is nil (e.g. User) or non-canonical" do
		person = Person.create!(name: "Elena", surname: "Vega")
		user   = User.create!(
			email: "elena.concern@mudclub.test",
			password: "SecurePassword123!",
			password_confirmation: "SecurePassword123!",
			person: person,
			club_id: nil
		)

		attach_test_image(user, filename: "elena_user.png")
		refute person.reload.avatar.attached?, "User must not overwrite Person avatar"

		# Merged (non-canonical) Person should not receive propagated avatars
		canonical = people(:alice)
		canonical.absorb!(person)
		member = Membership.create!(
			person: person,
			club: clubs(:test_club),
			kind: :athlete,
			status: :active,
			joined_on: Date.current
		)
		attach_test_image(member, filename: "merged_member.png")
		refute person.reload.avatar.attached?, "non-canonical Person must not receive avatar"
	end

	# ─── shift_avatar helper ─────────────────────────────────

	test "shift_avatar lifts nested person_attributes[:avatar] to top-level attrs" do
		member = Membership.new
		upload = fake_image_upload(filename: "shifted.png")
		attrs  = { person_attributes: { name: "Ana", avatar: upload } }

		member.send(:shift_avatar, attrs)

		assert_equal upload, attrs[:avatar]
		assert_nil attrs[:person_attributes][:avatar]
	end

	test "shift_avatar preserves explicit top-level attrs[:avatar] when both are present" do
		member     = Membership.new
		top_upload = fake_image_upload(filename: "top.png")
		sub_upload = fake_image_upload(filename: "sub.png")
		attrs      = { avatar: top_upload, person_attributes: { avatar: sub_upload } }

		member.send(:shift_avatar, attrs)

		assert_equal top_upload, attrs[:avatar]
		assert_equal sub_upload, attrs[:person_attributes][:avatar]
	end
end
