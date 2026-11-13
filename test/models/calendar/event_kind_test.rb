require "test_helper"

class EventKindTest < ActiveSupport::TestCase
	FakeEvent = Struct.new(:kind)

	test ".specific returns the subclass matching the canonical kind" do
		{
			holiday:     EventKind::Holiday,
			training:    EventKind::Training,
			match:       EventKind::Match,
			competition: EventKind::Competition,
			meeting:     EventKind::Base,
			social:      EventKind::Base,
			other:       EventKind::Base
		}.each do |kind, expected|
			assert_instance_of expected, EventKind.specific(event: FakeEvent.new(kind)),
				"expected #{expected} for #{kind}"
		end
	end

	test ".specific raises on blank kind" do
		error = assert_raises(ArgumentError) do
			EventKind.specific(event: FakeEvent.new(nil))
		end
		assert_match(/cannot be blank/, error.message)
	end

	test ".specific falls back to Base for kinds with no subclass" do
		assert_instance_of EventKind::Base,
			EventKind.specific(event: FakeEvent.new(:nonexistent))
	end
end
