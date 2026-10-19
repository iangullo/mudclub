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

	test "accepts uploaded video files only" do
		video = Event.new
		video.video.attach(io: file_fixture("clip.mp4").open, filename: "match.mp4")
		assert video.tap(&:validate).errors[:video].empty?
		assert video.has_video?

		notes = Event.new
		notes.video.attach(io: StringIO.new("not a video"), filename: "notes.txt")
		assert_not notes.tap(&:validate).errors[:video].empty?
	end

	test "limits the size of uploaded videos" do
		event = Event.new
		event.video.attach(io: file_fixture("clip.mp4").open, filename: "match.mp4")
		event.video.blob.define_singleton_method(:byte_size) { Event::VIDEO_MAX_SIZE + 1 }
		assert_not event.tap(&:validate).errors[:video].empty?
	end
end
