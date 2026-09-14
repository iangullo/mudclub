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
module LocationsHelper
	# return fields definition @title for forms
	def location_form(title:)
		res = location_title(title:)
		res << [ { kind: :text_box, key: :name, value: @location.name, placeholder: Location.val(:default), mandatory: { length: 3 } } ]
		res << [
			symbol_field("gmaps"),
			{ kind: :text_box, key: :gmaps_url, value: @location.gmaps_url, placeholder: Location.fld(:google_maps, :short) }
		]
		res << [
			symbol_field("training", { namespace: "sport" }),
			{ kind: :label_checkbox, key: :practice_court, label: Location.fld(:training_court) }
		]
		res.last << { kind: :hidden, key: :club_id, value: @club.id } if @club
		res.last << { kind: :hidden, key: :rdx, value: @rdx } if @rdx
		res
	end

	# return table for @locations TableComponent
	def location_table(locations: @locations)
		editor = u_admin? || (u_club == @club && (u_manager? || u_secretary?))
		title  = [
			{ kind: :normal, value: Location.fld(:name) },
			{ kind: :normal, value: Location.fld(:kind), align: :center },
			{ kind: :normal, value: Location.label(:short) }
		]
		title << button_field({ kind: :add, url: new_path_for(@club, :location), frame: :modal }) if editor

		rows = Array.new
		locations.each { |loc|
			url = editor ? path_for(loc, club: @club) : path_for(loc)
			row = { url:, frame: :modal, items: [] }
			row[:items] << { kind: :normal, value: loc.name }
			row[:items] << (loc.practice_court ? symbol_field("training", { namespace: "sport" }, align: :center) : symbol_field("home", align: :center))
			if loc.gmaps_url
				row[:items] << button_field({ kind: :location, symbol: "gmaps", align: :center, url: loc.gmaps_url }, align: :center)
			else
				row[:items] << { kind: :normal, value: "" }
			end
			row[:items] << button_field({ kind: :delete, url:, name: loc.name }) if editor
			rows << row
		}
		{ title:, rows: }
	end

	# specific search bar to search through drills
	def location_search_bar(search_in:, scratch: nil, cols: nil)
		session.delete("location_filters") if scratch
		fields = [
			{ kind: :search_text, key: :name, placeholder: Location.fld(:name), value: (params[:name].presence || session.dig("location_filters", "name")), size: 10 },
			{ kind: :hidden, key: :club_id, value: @club.id }
		]
		[ { kind: :search_box, url: search_in, fields:, cols: 2 } ]
	end

	def location_show
		res = location_title(title: @location.name)
		if @location.gmaps_url.present?
			res << [ button_field({ kind: :location, symbol: "gmaps", url: @location.gmaps_url, label: Location.val(:see) }) ]
		else
			res << [ { kind: :text, value: Location.val(:none) } ]
		end
		res << [ (@location.practice_court ? symbol_field("training", { namespace: "sport" }) : symbol_field("home")) ]
	end

	# return icon and top of fields definition
	def location_title(title:)
		clubid = @club&.id || u_clubid
		icon   =  ((u_clubid != clubid) ? @club&.logo : symbol_hash("location"))
		title_start(icon:, title:)
	end
end
