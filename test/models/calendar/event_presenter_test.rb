require "test_helper"

class EventPresenterTest < ActiveSupport::TestCase
	FakeEvent = Struct.new(:kind)

	test ".specific returns the subclass matching the canonical kind" do
		{
			holiday:     EventPresenter::Holiday,
			training:    EventPresenter::Training,
			match:       EventPresenter::Match,
			competition: EventPresenter::Competition,
			meeting:     EventPresenter::Base,
			social:      EventPresenter::Base,
			other:       EventPresenter::Base
		}.each do |kind, expected|
			assert_instance_of expected, EventPresenter.specific(event: FakeEvent.new(kind)),
				"expected #{expected} for #{kind}"
		end
	end

	test ".specific raises on blank kind" do
		error = assert_raises(ArgumentError) do
			EventPresenter.specific(event: FakeEvent.new(nil))
		end
		assert_match(/cannot be blank/, error.message)
	end

	test ".specific falls back to Base for kinds with no subclass" do
		assert_instance_of EventPresenter::Base,
			EventPresenter.specific(event: FakeEvent.new(:nonexistent))
	end
end
