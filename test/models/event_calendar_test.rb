require "test_helper"

class EventCalendarTest < ActiveSupport::TestCase
	# shared fixtures are out of sync with the schema: use in-memory records
	self.fixture_table_names = []

	setup do
		@locale     = I18n.locale
		I18n.locale = :en
		@team       = Team.new(name: "U18 male")
		@court      = Location.new(id: 3, name: "Indoor gym")
	end

	teardown do
		I18n.locale = @locale
	end

	test "wraps events in a named calendar using CRLF line endings" do
		ics = calendar(new_event(kind: :train)).to_ics
		assert ics.start_with?("BEGIN:VCALENDAR\r\nVERSION:2.0\r\n")
		assert ics.end_with?("END:VCALENDAR\r\n")
		assert_includes ics, "X-WR-CALNAME:U18 male\r\n"
		assert_equal 1, ics.scan("BEGIN:VEVENT").size
		assert_no_match(/[^\r]\n/, ics)
	end

	test "exports training sessions with floating local times" do
		ics = calendar(new_event(kind: :train)).to_ics
		assert_includes ics, "UID:event-7@mudclub.example\r\n"
		assert_includes ics, "DTSTAMP:20251001T120000Z\r\n"
		assert_includes ics, "DTSTART:20251020T180000\r\n"
		assert_includes ics, "DTEND:20251020T193000\r\n"
		assert_includes ics, "SUMMARY:Session: U18 male\r\n"
		assert_includes ics, "LOCATION:Indoor gym\r\n"
		assert_includes ics, "URL:https://mudclub.example/events/7\r\n"
	end

	test "lists home team first in match summaries" do
		home = calendar(new_event(kind: :match, name: "Rivals", home: true)).to_ics
		away = calendar(new_event(kind: :match, name: "Rivals", home: false)).to_ics
		assert_includes home, "SUMMARY:Match: U18 male - Rivals\r\n"
		assert_includes away, "SUMMARY:Match: Rivals - U18 male\r\n"
	end

	test "exports holidays as full-day events" do
		start = Time.utc(2025, 12, 24)
		ics   = calendar(new_event(kind: :rest, name: "Christmas", start_time: start, end_time: start + 1.day)).to_ics
		assert_includes ics, "DTSTART;VALUE=DATE:20251224\r\n"
		assert_includes ics, "DTEND;VALUE=DATE:20251225\r\n"
		assert_includes ics, "SUMMARY:Holiday: Christmas\r\n"
	end

	test "skips placeholder location" do
		ics = calendar(new_event(kind: :train, location: Location.new(id: 0, name: "none", gmaps_url: "https://maps.example"))).to_ics
		assert_not_includes ics, "LOCATION:"
		assert_not_includes ics, "DESCRIPTION:"
	end

	test "adds map link of the location when available" do
		assert_not_includes calendar(new_event(kind: :train)).to_ics, "DESCRIPTION:"
		@court.gmaps_url = "https://maps.app.goo.gl/abc123"
		assert_includes calendar(new_event(kind: :train)).to_ics, "DESCRIPTION:https://maps.app.goo.gl/abc123\r\n"
	end

	test "escapes text values and folds long lines" do
		suffix = " Ñandú" * 15
		ics    = calendar(new_event(kind: :match, name: "Rivals, Sporting; Club \\#{suffix}")).to_ics
		ics.split("\r\n").each { |line| assert_operator line.bytesize, :<=, 75 }
		assert ics.valid_encoding?
		assert_includes ics.gsub("\r\n ", ""), "SUMMARY:Match: U18 male - Rivals\\, Sporting\\; Club \\\\#{suffix}\r\n"
	end

	private
		def calendar(*events)
			EventCalendar.new(events, name: @team.to_s, host: "https://mudclub.example")
		end

		def new_event(kind:, location: @court, start_time: Time.utc(2025, 10, 20, 18), end_time: nil, **attrs)
			Event.new(id: 7, kind:, team: @team, location:, start_time:, end_time: end_time || start_time + 90.minutes,
				updated_at: Time.utc(2025, 10, 1, 12), **attrs)
		end
end
