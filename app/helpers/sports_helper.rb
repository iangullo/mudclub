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
			row[:items] << {kind: "normal", value: I18n.t("sport.#{sport.name}"), align: "center"}
			row[:items] << button_field({kind: "delete", url: row[:url], name: sport.to_s})
			rows << row
		}
		{title: title, rows: rows}
	end

	# home edit form fields
	def sports_form_fields(title:, retlnk: nil)
		res = [
			[
				{kind: "header-icon", value: "category.svg"},
				{kind: "title", value: title, cols: 2}
			],
			[
				{kind: "label", value: I18n.t("sport.single")},
				{kind: "text-box", key: :name, value: @sport.name, placeholder: "MudClub"}
			],
			[
				{kind: "gap"},
				{kind: "label", value: I18n.t("sport.single")},
				{kind: "select-collection", key: :sport_id, options: Sport.all, value: @sport.id}
			]
		]
		res << {kind: "hidden", key: :retlnk, value: retlnk} if retlnk
		res
	end
end
