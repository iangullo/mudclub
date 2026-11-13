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
# Training sessions
#
# app/models/calendar/event_kind/training.rb
class EventKind
	class Training < Base
		def self.slugs = %i[training train]
		def slug       = :training

		def created_notice = "#{notice(:created)} #{event.date_string}"
		def deleted_notice = "#{notice(:deleted)} #{event.date_string}"

		def updated_notice(initial, changed:)
			return I18n.t("status.no_data") unless changed
			"#{initial} #{event.date_string}"
		end
	end
end
