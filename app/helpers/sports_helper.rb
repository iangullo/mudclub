# MudClub - Simple Rails app to manage a team sports sport.
# Copyright (C) 2023  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
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
# View helpers for MudClub sports
module SportsHelper
	# sports page for admins
	def sports_grid
		title = [{kind: "normal", value: I18n.t("sport.single")}]
		title << button_field({kind: "add", url: new_sport_path, frame: "modal"})
		rows = Array.new
		Sport.all.each { |sport|
			row = {url: edit_sport_path(sport), items: [], frame: "modal"}
			row[:items] << {kind: "normal", value: sport.to_s, align: "center"}
			row[:items] << button_field({kind: "delete", url: row[:url], name: sport.to_s})
			rows << row
		}
		{title: title, rows: rows}
	end

	# show sport & related objects
	def sports_show_fields
		res = [
			[
				{kind: "header-icon", value: "sport.svg"},
				{kind: "title", value: @sport.to_s, cols: 2}
			],
			[{kind: "gap", size: 1}],
			[
				button_field({kind: "jump", icon: "category.svg", url: sport_categories_path(@sport), label: I18n.t("category.many")}, align: "center"),
				button_field({kind: "jump", icon: "division.svg", url: sport_divisions_path(@sport), label: I18n.t("division.many")}, align: "center")
			]
		]
		res
	end

	# sports edit fields
	def sports_form_fields(title:, retlnk: nil)
		res = [
			[
				{kind: "header-icon", value: "category.svg"},
				{kind: "title", value: title, cols: 2}
			],
			[
				{kind: "label", value: @sport.to_s}
			]
		]
		res << {kind: "hidden", key: :retlnk, value: retlnk} if retlnk
		res
	end
end
