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
# Basketball court layouts.
#
class Catalog::Basketball::CourtModes < Catalog::Base
	domain "sport.basketball"

	CATALOG = {

		full: {
			id: 0,

			description: "Full court.",

			dimensions: {
				width: 28.0,
				height: 15.0
			},

			halves: 2
		},

		half_off: {
			id: 1,

			description: "Half-court offense.",

			dimensions: {
				width: 14.0,
				height: 15.0
			},

			orientation: :offense,
			halves: 1
		},

		half_def: {
			id: 2,

			description: "Half-court defense.",

			dimensions: {
				width: 14.0,
				height: 15.0
			},

			orientation: :defense,
			halves: 1
		}

	}.freeze
end
