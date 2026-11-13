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
# app/models/calendar/event_kind/base.rb
class EventKind
	class Base
		attr_reader :event

		def initialize(event) = @event = event

		def self.slugs = raise NotImplementedError
		def self.available_for?(_scope) = true

		def slug = event.kind

		# ---- notices (step 1) ----
		def created_notice = notice(:created) + notice_suffix
		def deleted_notice = notice(:deleted) + notice_suffix

		def updated_notice(initial, changed:)
			return I18n.t("status.no_data") unless changed
			return initial if initial == I18n.t("stat.updated")
			initial + notice_suffix
		end

		private

		def notice(verb)
			I18n.t("calendar.event.messages.#{verb}", kind: event.kind_label)
		end

		def notice_suffix = ": #{event.to_s(style: "notice")}"

		public

		# ---- still-to-be-extracted API ----
		def defaults(date: nil)                     = raise NotImplementedError
		def title(show: nil, copy: nil, print: nil) = raise NotImplementedError
		def symbol                                  = raise NotImplementedError
		def to_s(style: nil)                        = raise NotImplementedError
		def to_hash(mode: 1)                        = raise NotImplementedError
		def form_fields(policy:, team: nil)         = raise NotImplementedError
		def show_fields(policy:, team: nil)         = raise NotImplementedError
		def pdf(_pdf_context) = nil
		def unlink_cleanup    = nil
	end
end
