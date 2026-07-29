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
# Catalog::Months
#
class Catalog::Months < Catalog::Base
	domain "calendar"

	CATALOG = {

		january:   { id: 1, days: 31 },
		february:  { id: 2, days: 28 },
		march:     { id: 3, days: 31 },
		april:     { id: 4, days: 30 },
		may:       { id: 5, days: 31 },
		june:      { id: 6, days: 30 },
		july:      { id: 7, days: 31 },
		august:    { id: 8, days: 31 },
		september: { id: 9, days: 30 },
		october:   { id: 10, days: 31 },
		november:  { id: 11, days: 30 },
		december:  { id: 12, days: 31 }

	}.freeze
end
