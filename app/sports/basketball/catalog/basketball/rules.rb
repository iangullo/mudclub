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
class Catalog::Basketball::Rules < Catalog::Base
	domain "sport.basketball"

	CATALOG = {

		fiba: {
			id: 0,
			description:
				"Official FIBA rules for standard five-on-five basketball.",
			players: 5,
			periods: 4
		},

		u14: {
			id: 1,
			description:
				"Adapted rules for under-14 competitions.",
			players: 5,
			periods: 4
		},

		u12: {
			id: 2,
			description:
				"Adapted rules for under-12 competitions.",
			players: 5,
			periods: 6
		},

		u10: {
			id: 3,
			description:
				"Adapted rules for under-10 competitions.",
			players: 5,
			periods: 4
		},

		u8: {
			id: 4,
			description:
				"Adapted rules for under-8 competitions.",
			players: 5,
			periods: 4
		},

		three: {
			id: 5,
			description:
				"Official FIBA 3×3 basketball rules.",
			players: 3,
			periods: 1
		}

	}.freeze
end
