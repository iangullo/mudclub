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
#
# Catalog::EventKinds
#
class Catalog::EventKinds < Catalog::Base
	domain "calendar"

	CATALOG = {
		holiday: {
			id: 0
		},

		training: {
			id: 1,
			tracks_attendance: true
		},

		competition: {
			id: 2,
			tracks_attendance: true
		},

		meeting: {
			id: 10,
			tracks_attendance: true
		},

		social: {
			id: 20,
			tracks_attendance: true
		},

		other: {
			id: 99
		},

		#
		# Legacy enum aliases
		#
		rest: {
			deprecated: true,
			alias_of: :holiday
		},

		train: {
			deprecated: true,
			alias_of: :training
		},

		match: {
			deprecated: true,
			alias_of: :competition
		}
	}.freeze
end
