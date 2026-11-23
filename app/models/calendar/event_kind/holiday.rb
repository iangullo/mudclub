# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
# Holiday events
#
# app/models/calendar/event_kind/holiday.rb
class EventKind
	class Holiday < Base
		def self.slugs = %i[holiday rest]
		def has_time?  = false
		def slug       = :holiday
		def title_rows = 3

		def header_fragments(view, res:, form: nil, cols: nil, **)
			t = team
			res << [ { kind: :subtitle, value: t&.nick || "", cols: } ] if t
			if form
				res << [ { kind: :text_box, key: :name, value: event.name,
									placeholder: event.kind_label, cols: cols.to_i + 4, size: 22 } ]
			else
				res << [ view.label_item(event.name) ]
			end
			res
		end
	end
end
