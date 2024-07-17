# MudClub - Simple Rails app to manage a team sports club.
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
module DivisionsHelper
	# return icon and top of FieldsComponent
	def division_title_fields(title:, subtitle: nil, cols: nil)
		title_start(icon: "division.svg", title:, subtitle:, cols:)
	end

	# return FieldsComponent @fields for forms
	def division_form_fields(title:, subtitle:)
		res = division_title_fields(title:, subtitle:, cols: 3)
		res << [{kind: "text-box", key: :name, value: @division.name, placeholder: I18n.t("division.name"),cols: 3, mandatory: {length: 3}}]
	end

	# return grid for @divisions GridComponent
	def division_grid
		title = [{kind: "normal", value: I18n.t("division.name")}]
		title << button_field({kind: "add", url: new_sport_division_path(@sport), frame: "modal"}) if u_admin?

		rows = Array.new
		@divisions.each { |div|
			row = {url: edit_sport_division_path(@sport, div), frame: "modal", items: []}
			row[:items] << {kind: "normal", value: div.name}
			row[:items] << button_field({kind: "delete", url: sport_division_path(@sport, div), name: div.name}) if u_admin?
			rows << row
		}
		{title: title, rows: rows}
	end
end
