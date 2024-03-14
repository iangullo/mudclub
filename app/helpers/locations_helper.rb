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
	# return FieldsComponent @title for forms
	def location_form_fields(title:)
		res = location_title_fields(title:)
		res << [{kind: "text-box", key: :name, value: @location.name, placeholder: I18n.t("location.default")}]
		res << [
			{kind: "icon", value: "gmaps.svg"},
			{kind: "text-box", key: :gmaps_url, value: @location.gmaps_url, placeholder: I18n.t("location.gmaps")}
		]
		res << [
			{kind: "icon", value: "training.svg"},
			{kind: "label-checkbox", key: :practice_court, label: I18n.t("location.train")}
		]
		res.last << {kind: "hidden", key: :club_id, value: @clubid} if @clubid
		res
	end

	# return grid for @locations GridComponent
	def location_grid(locations: @locations)
		editor = u_admin? || (u_manager? && u_clubid==@clubid)
		title  = [
			{kind: "normal", value: I18n.t("location.name")},
			{kind: "normal", value: I18n.t("kind.single"), align: "center"},
			{kind: "normal", value: I18n.t("location.abbr")}
		]
		title << button_field({kind: "add", url: new_location_path(club_id: @club&.id), frame: "modal"}) if editor

		rows = Array.new
		locations.each { |loc|
			url = editor ? location_path(loc, club_id: @clubid) : "#"
			row = {url:, frame: "modal", items: []}
			row[:items] << {kind: "normal", value: loc.name}
			row[:items] << {kind: "icon", value: loc.practice_court ? "training.svg" : "home.svg", align: "center"}
			if loc.gmaps_url
				row[:items] << button_field({kind: "location", icon: "gmaps.svg", align: "center", url: loc.gmaps_url}, align: "center")
			else
				row[:items] << {kind: "normal", value: ""}
			end
			row[:items] << button_field({kind: "delete", url:, name: loc.name}) if editor
			rows << row
		}
		{title:, rows:}
	end

	# specific search bar to search through drills
	def location_search_bar(search_in:, scratch: nil, cols: nil)
		session.delete('location_filters') if scratch
		fields = [
			{kind: "search-text", key: :name, placeholder: I18n.t("location.name"), value: (params[:name].presence || session.dig('location_filters', 'name')), size: 10},
			{kind: "hidden", key: :club_id, value: @clubid},
		]
		[{kind: "search-box", url: search_in, fields:, cols: 2}]
	end
	
	def location_show_fields
		res = location_title_fields(title: @location.name)
		if @location.gmaps_url.present?
			res << [button_field({kind: "location", icon: "gmaps.svg", url: @location.gmaps_url, label: I18n.t("location.see")})]
		else
			res << [{kind: "text", value: I18n.t("location.none")}]
		end
		res << [{kind: "icon", value: @location.practice_court ? "training.svg" : "home.svg"}]
	end

	# return icon and top of FieldsComponent
	def location_title_fields(title:)
		clubid = @club&.id || @clubid || u_clubid
		icon   =  ((u_clubid != clubid) ? @club&.logo : "location.svg")
		title_start(icon:, title:)
	end
end
