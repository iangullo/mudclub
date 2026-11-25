require "test_helper"

class RelationshipTest < ActiveSupport::TestCase
	# ─── Validations ─────────────────────────────────────────

	test "validates presence of person, related_person, and kind" do
		rel = Relationship.new
		refute rel.valid?
		assert rel.errors[:person].any?
		assert rel.errors[:related_person].any?
		assert rel.errors[:kind].any?
	end

	test "cannot relate a person to themselves" do
		alice = people(:alice)
		rel = Relationship.new(person: alice, related_person: alice, kind: :parent)
		refute rel.valid?
		assert rel.errors.added?(:related_person, :same_person)
	end

	test "enforces uniqueness of [person_id, related_person_id, kind]" do
		minor  = people(:bob)
		parent = people(:alice)

		Relationship.create!(person: minor, related_person: parent, kind: :parent)

		duplicate = Relationship.new(person: minor, related_person: parent, kind: :parent)
		refute duplicate.valid?
		assert duplicate.errors[:person_id].any?

		# Different kind between the same two people is permitted
		different_kind = Relationship.new(person: minor, related_person: parent, kind: :emergency_contact)
		assert different_kind.valid?
	end

	test "propagates related_person validation errors onto related_person" do
		minor = people(:bob)
		invalid_person = Person.new(name: "", surname: "")

		rel = Relationship.new(person: minor, related_person: invalid_person, kind: :parent)
		refute rel.valid?
		assert rel.errors[:related_person].any?
	end

	# ─── Direction, Normalization & Perspective ──────────────

	test "kind_for returns stored kind for subject and inverse_kind for related_person" do
		minor  = people(:bob)
		parent = people(:alice)
		rel = Relationship.create!(person: minor, related_person: parent, kind: :parent)

		assert_equal :parent, rel.kind_for(minor)
		assert_equal :child, rel.kind_for(parent)
		assert_equal :parent, rel.kind_for(nil)
	end

	test "normalize! flips non-selectable inverse kinds into canonical direction" do
		minor  = people(:bob)
		parent = people(:alice)

		rel = Relationship.new(person: minor, related_person: parent, kind: :child)
		rel.normalize!

		assert_equal parent, rel.person
		assert_equal minor, rel.related_person
		assert_equal :parent, rel.kind.to_sym
	end

	test "creating a relationship stores a single canonical row without duplicate mirror rows" do
		minor  = people(:bob)
		parent = people(:alice)

		assert_difference -> { Relationship.count }, 1 do
			Relationship.create!(person: minor, related_person: parent, kind: :parent)
		end

		assert_equal 1, minor.relationships.count
		assert_equal 0, minor.inverse_relationships.count
		assert_equal 1, parent.inverse_relationships.count
		assert_equal 0, parent.relationships.count
	end

	# ─── Scopes & Builders ───────────────────────────────────

	test "in_group filters by catalog group and raises on unknown group" do
		minor  = people(:bob)
		parent = people(:alice)
		rel = Relationship.create!(person: minor, related_person: parent, kind: :parent)

		assert_includes Relationship.in_group(:responsible_adult), rel
		assert_raises(ArgumentError) { Relationship.in_group(:nonexistent_group) }
	end

	test "build_for initializes relationship with an empty related_person" do
		minor = people(:bob)
		rel = Relationship.build_for(minor, kind: :parent)

		assert_equal minor, rel.person
		assert_equal :parent, rel.kind.to_sym
		assert rel.related_person.present?
		assert rel.related_person.new_record?
	end

	test "rebuild marks error when related_person_attributes match multiple candidates" do
		minor = people(:bob)
		Person.create!(name: "Carlos", surname: "López")
		Person.create!(name: "Carlos", surname: "López")

		rel = Relationship.new
		rel.rebuild(minor, {
			kind: :parent,
			related_person_attributes: { name: "Carlos", surname: "López" }
		})

		assert rel.errors.added?(:related_person, :ambiguous)
	end
end
