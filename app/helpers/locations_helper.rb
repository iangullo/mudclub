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
module LocationsHelper
	# return icon and top of FieldsComponent
	def location_title_fields(title:)
		title_start(icon: "location.svg", title: title)
	end

	def location_show_fields
		res = location_title_fields(title: @location.name)
		res << [(@location.gmaps_url and @location.gmaps_url.length > 0) ? {kind: "location", url: @location.gmaps_url, name: I18n.t("location.see")} : {kind: "text", value: I18n.t("location.none")}]
		res << [{kind: "icon", value: @location.practice_court ? "training.svg" : "team.svg"}]
	end

	# return FieldsComponent @title for forms
	def location_form_fields(title:)
		res = location_title_fields(title:)
		res << [{kind: "text-box", key: :name, value: @location.name, size: 20}]
		res << [
			{kind: "icon", value: "gmaps.svg"},
			{kind: "text-box", key: :gmaps_url, value: @location.gmaps_url, size: 20}
		]
		res << [
			{kind: "icon", value: "training.svg"},
			{kind: "label-checkbox", key: :practice_court, label: I18n.t("location.train")}
		]
		res.last << {kind: "hidden", key: :season_id, value: @season.id} if @season
		res
	end

	# return grid for @locations GridComponent
	def location_grid
		title = [
			{kind: "normal", value: I18n.t("location.name")},
			{kind: "normal", value: I18n.t("kind.single"), align: "center"},
			{kind: "normal", value: I18n.t("location.abbr")}
		]
		title << {kind: "add", url: @season ? season_locations_path(@season)+"/new" : new_location_path, frame: "modal"} if u_admin? or u_coach?

		rows = Array.new
		@locations.each { |loc|
			row = {url: edit_location_path(loc), frame: "modal", items: []}
			row[:items] << {kind: "normal", value: loc.name}
			row[:items] << {kind: "icon", value: loc.practice_court ? "training.svg" : "team.svg", align: "center"}
			if loc.gmaps_url
				row[:items] << {kind: "location", icon: "gmaps.svg", align: "center", url: loc.gmaps_url}
			else
				row[:items] << {kind: "normal", value: ""}
			end
			row[:items] << {kind: "delete", url: location_path(loc, season_id: @season ? @season.id : nil), name: loc.name} if u_admin?
			rows << row
		}
		{title: title, rows: rows}
	end
end
