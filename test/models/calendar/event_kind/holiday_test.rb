require "test_helper"

class EventKind::HolidayTest < ActiveSupport::TestCase
	def setup
		@event = FakeEvent.new(kind: :holiday, name: "Bank Holiday",
			label: "Holiday", date_string: "15/01/2026")
		@kind  = EventKind::Holiday.new(@event)
	end

	test "#created_notice includes the kind label and the title" do
		notice = @kind.created_notice
		assert_includes notice, "Holiday"
		assert_includes notice, "Bank Holiday"
	end

	test "#created_notice is not blank (regression: legacy helper returned nil)" do
		assert_predicate @kind.created_notice, :present?
	end

	test "#deleted_notice includes the kind label and the title" do
		notice = @kind.deleted_notice
		assert_includes notice, "Holiday"
		assert_includes notice, "Bank Holiday"
	end
end
