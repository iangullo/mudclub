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
# Basketball game periods.
#
class Catalog::Basketball::Periods < Catalog::Base
	domain "sport.basketball"

	CATALOG = {

		#
		# Summary
		#

		tot: {
			id: 0,

			description: "Complete game.",

			total: true,
			category: :summary
		},

		#
		# Regulation periods
		#

		q1: {
			id: 1,

			description: "First period.",

			category: :regular,
			order: 1
		},

		q2: {
			id: 2,

			description: "Second period.",

			category: :regular,
			order: 2
		},

		q3: {
			id: 3,

			description: "Third period.",

			category: :regular,
			order: 3
		},

		q4: {
			id: 4,

			description: "Fourth period.",

			category: :regular,
			order: 4
		},

		#
		# Optional regulation periods
		#

		q5: {
			id: 5,

			description: "Fifth period.",

			category: :regular,
			order: 5
		},

		q6: {
			id: 6,

			description: "Sixth period.",

			category: :regular,
			order: 6
		},

		#
		# Overtime
		#

		ot: {
			id: 7,

			description: "Overtime.",

			category: :extra,
			order: 99
		}

	}.freeze
end
