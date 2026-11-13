require "test_helper"

class EventKind::BaseTest < ActiveSupport::TestCase
	def setup
		@event = FakeEvent.new(kind: :meeting, date_string: "15/01/2026")
		@kind  = EventKind::Base.new(@event)
	end

	test "#slug falls back to the event's canonical kind" do
		assert_equal :meeting, @kind.slug
	end

	test "#created_notice is present" do
		assert_predicate @kind.created_notice, :present?
	end

	test "#created_notice interpolates the kind label" do
		I18n.with_locale(:en) do
			assert_includes @kind.created_notice, "Meeting"
		end
	end

	test "#deleted_notice interpolates the kind label" do
		I18n.with_locale(:en) do
			assert_includes @kind.deleted_notice, "Meeting"
		end
	end

	test "#updated_notice returns no-data message when not changed" do
		assert_equal I18n.t("status.no_data"),
			@kind.updated_notice("whatever", changed: false)
	end

	test "#updated_notice does not append suffix when initial is stat.updated" do
		initial = I18n.t("stat.updated")
		assert_equal initial, @kind.updated_notice(initial, changed: true)
	end

	test "#updated_notice appends the notice suffix otherwise" do
		assert @kind.updated_notice("Something", changed: true).end_with?("(15/01/2026)")
	end
end
