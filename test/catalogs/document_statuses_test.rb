# test/catalogs/document_statuses_test.rb
require "test_helper"
require_relative "catalog_contract"

class DocumentStatusesTest < ActiveSupport::TestCase
	include CatalogContract

	def catalog = Catalog::DocumentStatuses

	def test_exposes_the_expected_lifecycle
		expected = %i[draft pending verified active rejected superseded archived]
		assert_equal expected.sort, catalog.keys.sort
	end

	def test_entries_are_ordered_draft_to_terminal
		orders = catalog.values.map { |e| e[:order] }
		assert_equal orders.sort, orders
	end

	def test_only_draft_and_rejected_are_editable
		editable = catalog.values.select(&:editable?).map(&:key)
		assert_equal %i[draft rejected].sort, editable.sort
	end

	def test_only_superseded_and_archived_are_terminal
		terminal = catalog.values.select(&:terminal?).map(&:key)
		assert_equal %i[archived superseded].sort, terminal.sort
	end

	def test_every_entry_publishes_color_and_icon
		catalog.values.each do |entry|
			assert_kind_of Symbol, entry.color, "#{entry.key} missing :color"
			assert_kind_of Symbol, entry.icon,  "#{entry.key} missing :icon"
		end
	end

	def test_enum_values_are_stable
		assert_equal 10, catalog.enum[:draft]
		assert_equal 40, catalog.enum[:active]
	end

	def test_document_model_can_be_constructed_with_status
		doc = Document.new(kind: :other, status: :draft)
		assert_equal "draft", doc.status
		assert doc.draft?
	end
end
