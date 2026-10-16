# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
# EventCalendar - export a collection of Events as an iCalendar (RFC 5545)
# file, so they can be imported into Google/Apple/Outlook calendars.
#   => name: calendar name shown by the calendar application
#   => host: base url of this MudClub server, used for event links & UIDs
class EventCalendar
	CRLF = "\r\n"

	def initialize(events, name:, host:)
		@events = events
		@name   = name
		@host   = host
	end

	def to_ics
		lines = [ "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//MudClub//Events//EN", "CALSCALE:GREGORIAN" ]
		lines << "X-WR-CALNAME:#{escape(@name)}"
		@events.each { |event| lines.concat(vevent(event)) }
		lines << "END:VCALENDAR"
		lines.map { |line| fold(line) }.join(CRLF) + CRLF
	end

	private
		def vevent(event)
			lines = [ "BEGIN:VEVENT", "UID:event-#{event.id}@#{URI(@host).host}" ]
			lines << "DTSTAMP:#{event.updated_at.utc.strftime("%Y%m%dT%H%M%SZ")}"
			if event.rest?	# holidays are full-day events, DTEND is exclusive
				lines << "DTSTART;VALUE=DATE:#{event.start_date.strftime("%Y%m%d")}"
				lines << "DTEND;VALUE=DATE:#{[ event.end_time.to_date, event.start_date + 1 ].max.strftime("%Y%m%d")}"
			else	# times are stored as club local time: export as "floating" times
				lines << "DTSTART:#{event.start_time.strftime("%Y%m%dT%H%M%S")}"
				lines << "DTEND:#{event.end_time.strftime("%Y%m%dT%H%M%S")}"
			end
			lines << "SUMMARY:#{escape(summary(event))}"
			if event.location_id.to_i > 0
				lines << "LOCATION:#{escape(event.location.to_s)}"
				lines << "DESCRIPTION:#{escape(event.location.gmaps_url)}" if event.location.gmaps_url.present?	# directions link
			end
			lines << "URL:#{@host}/events/#{event.id}"
			lines << "END:VEVENT"
		end

		# "Match: Home - Away", "Session: Team" or "Holiday: name"
		def summary(event)
			case event.kind.to_sym
			when :match
				opponent = event.name.presence || "?"
				detail   = event.home? ? "#{event.team} - #{opponent}" : "#{opponent} - #{event.team}"
			when :train
				detail = event.team.to_s
			when :rest
				detail = event.name
			end
			[ I18n.t("#{event.kind}.single"), detail.presence ].compact.uniq.join(": ")
		end

		# escape TEXT values as required by RFC 5545 (3.3.11)
		def escape(text)
			text.to_s.gsub(/[\\,;]/) { |c| "\\#{c}" }.gsub(/\r?\n/, "\\n")
		end

		# fold lines longer than 75 octets without splitting multi-byte chars (RFC 5545 3.1)
		def fold(line)
			return line if line.bytesize <= 75
			folded = [ +"" ]
			line.each_char do |char|
				folded << +" " if folded.last.bytesize + char.bytesize > 75
				folded.last << char
			end
			folded.join(CRLF)
		end
end
