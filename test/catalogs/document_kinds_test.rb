# test/catalogs/document_kinds_test.rb
require "test_helper"
require_relative "catalog_contract"

class DocumentKindsTest < ActiveSupport::TestCase
	include CatalogContract

	def catalog = Catalog::DocumentKinds

	# -------- 7.1 / 7.2 invariants --------

	def test_every_entry_declares_a_workflow
		catalog.entries.each_value do |entry|
			assert entry.metadata.key?(:workflow),
				"#{entry.key} is missing :workflow"
			assert_includes %i[simple reviewed], entry.workflow,
				"#{entry.key} has invalid workflow #{entry.workflow.inspect}"
		end
	end

	def test_multiple_and_versioned_are_mutually_exclusive
		conflicting = catalog.values.select do |e|
			e.multiple? && e.fetch(:versioned, false)
		end
		assert_empty conflicting.map(&:key),
			"These entries combine multiple:true with versioned:true — forbidden (7.2)"
	end

	def test_versioned_flag_is_boolean_when_present
		catalog.entries.each_value do |entry|
			next unless entry.metadata.key?(:versioned)
			assert_includes [ true, false ], entry.versioned,
				"#{entry.key}: expected boolean :versioned, got #{entry.versioned.inspect}"
		end
	end

	def test_every_entry_declares_applies_to
		catalog.entries.each_value do |entry|
			assert entry.applies_to.present?, "#{entry.key} missing :applies_to"
		end
	end

	# -------- owner-scoped lookups --------

	def test_option_list_for_club
		kinds = catalog.option_list(applies_to: :club).map(&:last)
		assert_includes kinds, :athlete_terms
		assert_includes kinds, :privacy_policy
		assert_includes kinds, :other
		refute_includes kinds, :photo
		refute_includes kinds, :medical_certificate
	end

	def test_option_list_for_person
		kinds = catalog.option_list(applies_to: :person).map(&:last)
		assert_includes kinds, :photo
		assert_includes kinds, :id_front
		assert_includes kinds, :other
		refute_includes kinds, :athlete_terms
	end

	def test_option_list_for_registration
		kinds = catalog.option_list(applies_to: :registration).map(&:last)
		assert_includes kinds, :parental_authorization
		assert_includes kinds, :athlete_form
		refute_includes kinds, :privacy_policy
	end

	# -------- Document integration (fixtures :all) --------

	def test_document_kind_list_for_club_fixture
		club  = clubs(:test_club)
		kinds = Document.kind_list(club).map(&:last)
		assert_includes kinds, :athlete_terms
		refute_includes kinds, :photo
	end

	def test_document_kind_list_for_person_fixture
		person = people(:alice)
		kinds  = Document.kind_list(person).map(&:last)
		assert_includes kinds, :photo
		refute_includes kinds, :athlete_terms
	end
end
