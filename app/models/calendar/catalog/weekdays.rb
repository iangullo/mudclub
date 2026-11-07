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
# Catalog::Weekdays
#
class Catalog::Weekdays < Catalog::Base
	domain "calendar"

	CATALOG = {

		monday:    { id: 1, working_day: true },
		tuesday:   { id: 2, working_day: true },
		wednesday: { id: 3, working_day: true },
		thursday:  { id: 4, working_day: true },
		friday:    { id: 5, working_day: true },
		saturday:  { id: 6, working_day: false },
		sunday:    { id: 7, working_day: false }

	}.freeze
end
