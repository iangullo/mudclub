require "test_helper"

class EventKind::TrainingTest < ActiveSupport::TestCase
	def setup
		@event = FakeEvent.new(kind: :training,
			label: "Training", date_string: "15/01/2026")
		@kind  = EventKind::Training.new(@event)
	end

	test "#created_notice ends with the date" do
		assert @kind.created_notice.end_with?("15/01/2026")
	end

	test "#created_notice does not append the title" do
		refute_includes @kind.created_notice, "(15/01/2026)"
	end

	test "#updated_notice always appends the date (even for stat.updated)" do
		initial = I18n.t("stat.updated")
		assert_equal initial + " 15/01/2026",
			@kind.updated_notice(initial, changed: true)
	end
end
