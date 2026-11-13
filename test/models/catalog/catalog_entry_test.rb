# test/models/catalog_entry_test.rb
require "test_helper"

class CatalogEntryTest < ActiveSupport::TestCase
	def entry = Catalog::DocumentStatuses.fetch(:draft)

	def test_exposes_attributes_via_method_missing
		assert_equal 0,     entry.order
		assert_equal :grey, entry.color
	end

	def test_predicate_readers_are_boolean_when_key_exists
		assert_equal true,  entry.editable?
		assert_equal false, entry.terminal?
	end

	def test_unknown_predicate_returns_nil
		entry = Catalog::Entry.new(
			catalog:    Object.new,
			key:        :whatever,
			attributes: { name: "Whatever" }   # no :unknown_predicate key
		)

		assert_nil entry.unknown_predicate?
		refute entry.respond_to?(:unknown_predicate)
	end

	def test_unknown_reader_returns_nil
		entry = Catalog::Entry.new(
			catalog:    Object.new,
			key:        :whatever,
			attributes: { name: "Whatever" }
		)

		assert_nil entry.unknown_reader
		refute entry.respond_to?(:unknown_reader)
	end

	def test_entries_are_comparable_by_id
		assert_operator Catalog::DocumentStatuses.fetch(:draft), :<,
										Catalog::DocumentStatuses.fetch(:active)
	end

	def test_entries_are_frozen
		assert entry.frozen?
	end

	def test_entry_identity
		I18n.with_locale(:en) do
			assert_equal Catalog::DocumentStatuses, entry.catalog
			assert_equal :draft, entry.key
			assert_equal "Draft", entry.label
		end
	end
end
