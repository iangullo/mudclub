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
# app/sports/basketball/catalog/basketball/drill_categories.rb
#
# Basketball drill/play categories.
#
class Catalog::Basketball::DrillCategories < Catalog::DrillCategories
	domain "sport.basketball"

	CATALOG = Catalog::DrillCategories::CATALOG.merge(
		# --- Themes -------------------------------------------------------------
		shooting:              { id: 10 },
		rebounding:            { id: 11 },
		cuts:                  { id: 12 },
		pressure:              { id: 13 },
		inbound:               { id: 14 },
		play:                  { id: 15 },

		# --- Drill formats (NxM) ------------------------------------------------
		one_v_zero:            { id: 20 },
		one_v_one:             { id: 21 },
		one_v_one_plus_one:    { id: 22 },
		two_v_zero:            { id: 23 },
		two_v_one:             { id: 24 },
		two_v_two:             { id: 25 },
		two_v_two_plus_one:    { id: 26 },
		two_v_two_plus_two:    { id: 27 },
		three_v_zero:          { id: 28 },
		three_v_two:           { id: 29 },
		three_v_three:         { id: 30 },
		four_v_zero:           { id: 31 },
		four_v_two:            { id: 32 },
		four_v_four:           { id: 33 },
		five_v_zero:           { id: 34 },
		five_v_five:           { id: 35 },
		fiba_three_v_three:    { id: 36 }
	).freeze
end
