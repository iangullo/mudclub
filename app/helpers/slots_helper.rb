# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
module SlotsHelper
	def render_chunk_cell(chunk, slice)
		base_classes = "text-center"

		if chunk[:slot]
			render_slot_chunk(chunk, base_classes)
		elsif chunk[:gap]
			render_gap_chunk(chunk, slice, base_classes)
		else
			render_empty_chunk(chunk, slice, base_classes)
		end
	end

	# return icon and top of definition
	def slot_title(title:, subtitle: nil)
		icon = symbol_hash("timetable")
		res  = title_start(icon:, title:, subtitle:)
		res
	end

	# return definition @fields for forms
	def slot_form(title:)
		res = slot_title(title:, subtitle: @season&.name)
		res << [
			symbol_field("team"),
			{ kind: :select_collection, key: :team_id, options: @club.teams.where(season_id: @season.id), value: @slot.team_id, cols: 2 }
		]
		res << [
			symbol_field("location"),
			{ kind: :select_collection, key: :location_id, options: @locations, value: @slot.location_id, cols: 2 }
		]
		res << [
			symbol_field("calendar"),
			{ kind: :select_box, key: :wday, value: @slot.wday, options: weekdays },
			{ kind: :time_box, hour: @slot.hour, mins: @slot.min, mandatory: true }
		]
		res << [
			symbol_field("clock"),
			{ kind: :number_box, key: :duration, min: 60, max: 120, step: 15, size: 3, value: @slot.duration, units: I18n.t("calendar.mins"), mandatory: { min: 60 } }
		]
		res.last << { kind: :hidden, key: :season_id, value: @season.id }
		res.last << { kind: :hidden, key: :rdx, value: @rdx } if @rdx
		res
	end

	# search bar for slots index
	def slot_search_bar(full = false)
		l_opts   = @locations.practice.select(:id, :name)
		l_filter = { kind: :search_collection, key: :location_id, options: l_opts, value: @location.id }
		fields   = [ l_filter, { kind: :hidden, key: :club_id, value: @clubid } ]
		if full
			s_filter = { kind: :search_collection, key: :season_id, options: Season.real, value: @season&.id }
			fields = [ s_filter ] + fields
			res = []
		else
			fields << { kind: :hidden, key: :season_id, value: @seasonid }
			res = [ gap_field(size: 1) ]
		end
		res << { kind: :search_box, url: club_slots_path(@clubid, rdx: @rdx), fields: }
	end

	# fields for individual slot views
	def slot_show
		res = [
			[ symbol_field("category", { namespace: "sport" }), string_field(@slot.team.category.name, cols: 2) ],
			[ symbol_field("division", { namespace: "sport" }), string_field(@slot.team.division.name, cols: 2) ],
			[ symbol_field("location"), string_field(@slot.court, cols: 2) ],
			[ symbol_field("calendar"), string_field(@slot.to_s, cols: 2) ]
		]
		if u_manager?
			res << [ gap_field(cols: 2), button_field({ kind: :delete, url: slot_path(@slot, rdx: @rdx), name: @slot.to_s }, align: "right") ]
		end
		res
	end

	private
		def render_slot_chunk(chunk, base_classes)
			slot = chunk[:slot]
			classes = "#{base_classes} bg-blue-300 align-center rounded-lg hover:text-white hover:bg-blue-700 cursor-pointer border border-blue-500"
			lclass  = "text-xs"

			content_tag(:td,
				class: classes,
				rowspan: chunk[:rows],
				colspan: chunk[:cols],
				data: { controller: "hover", action: "click->modal#open" }) do
				link_to(slot_path(slot),
								class: "block p-1",
								data: { turbo_frame: "modal" }) do
					safe_join([
						content_tag(:div, slot.team.to_s, class: "font-semibold #{lclass} md:text-sm"),
						(slot.team.to_s != slot.team.category.to_s ?
							content_tag(:div, slot.team.category.to_s, class: lclass) : nil),
						content_tag(:div, slot.team.division.to_s, class: lclass),
						content_tag(:div, slot.to_s(false), class: lclass)
					].compact)
				end
			end
		end

		def render_gap_chunk(chunk, slice, base_classes)
			content_tag(:td,
				class: base_classes,
				rowspan: chunk[:rows],
				colspan: chunk[:cols]) do
				if chunk[:wday] && slice[:time]
					safe_join([
						content_tag(:div, chunk[:wday], class: "font-medium hidden md:block"),
						content_tag(:div, "#{slice[:time].strftime('%H:%M')}", class: "text-xs")
					])
				else
					content_tag(:span, "", class: "text-xs")
				end
			end
		end

		def render_empty_chunk(chunk, slice, base_classes)
			content_tag(:td,
				class: base_classes,
				rowspan: chunk[:rows],
				colspan: chunk[:cols]) do
				if chunk[:wday] && slice[:time]
					content_tag(:div, "#{chunk[:wday]} #{slice[:time].strftime('%H:%M')}",
										class: "text-xs text-gray-300")
				else
					content_tag(:span, "", class: "text-xs")
				end
			end
		end

		# returns an array with weekday names and their id
		def weekdays
			res =[]
			1.upto(5) { |i|res << [ I18n.t("calendar.daynames")[i], i ] }
			res
		end
end
