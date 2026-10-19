require "test_helper"

class EventTest < ActiveSupport::TestCase
	# shared fixtures are out of sync with the schema: use in-memory records
	self.fixture_table_names = []

	test "reads the id of YouTube video links" do
		[
			"https://www.youtube.com/watch?v=dQw4w9WgXcQ",
			"https://youtube.com/watch?feature=share&v=dQw4w9WgXcQ&t=42",
			"https://m.youtube.com/watch?v=dQw4w9WgXcQ",
			"https://youtu.be/dQw4w9WgXcQ?si=abc",
			"youtu.be/dQw4w9WgXcQ",
			"https://www.youtube.com/embed/dQw4w9WgXcQ",
			"https://www.youtube.com/shorts/dQw4w9WgXcQ",
			"https://www.youtube.com/live/dQw4w9WgXcQ?feature=share",
			" https://youtu.be/dQw4w9WgXcQ "
		].each { |url| assert_equal "dQw4w9WgXcQ", Event.new(video_url: url).video_id, url }
	end

	test "only accepts YouTube links as match videos" do
		assert Event.new(video_url: nil).tap(&:validate).errors[:video_url].empty?
		assert Event.new(video_url: "https://youtu.be/dQw4w9WgXcQ").tap(&:validate).errors[:video_url].empty?
		[ "https://vimeo.com/123456", "https://youtube.com.evil.test/watch?v=dQw4w9WgXcQ", "https://youtu.be/short", "not a link" ].each do |url|
			event = Event.new(video_url: url)
			assert_nil event.video_id, url
			assert_not event.tap(&:validate).errors[:video_url].empty?, url
		end
	end
end
