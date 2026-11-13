require "test_helper"

class EventKind::MatchTest < ActiveSupport::TestCase
	def setup
		@event = FakeEvent.new(kind: :match, label: "Match", date_string: "15/01/2026")
		@kind  = EventKind::Match.new(@event)
	end

	test "#created_notice includes kind label and title" do
		notice = @kind.created_notice
		assert_includes notice, "Match"
		assert_includes notice, "15/01/2026"
	end
end

class EventKind::CompetitionTest < ActiveSupport::TestCase
	test "inherits Match#created_notice" do
		event = FakeEvent.new(kind: :competition,
			label: "Competition", date_string: "15/01/2026")
		assert_includes EventKind::Competition.new(event).created_notice, "Competition"
	end
end
