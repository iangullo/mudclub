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
# frozen_string_literal: true

# GridComponent - manage data grids as ViewComponent
# Each grid has two parts:
#   => title items:
#      => kind: :normal | :inverse | :gap | :button
#      => value: associated text
#      => class: optional (unrequired?)
#   => row items: have links in them (per row)
#   => data: data for the stimulus controller (optional)
# optional:
#   => form: form object (if needed)
#   => controller: stimulus controller for dynamic view updates
class GridComponent < ApplicationComponent
	attr_writer :form

	def initialize(grid:, form: nil, controller: nil, data: nil)
		@form   = form
		@title  = parse_title(grid[:title])
		@rows   = parse_rows(grid[:rows])
		if controller	# add stimulus controller and data
			@controller = controller
			@data       = grid[:data].merge(action: "change->#{controller}#update")
		end
		if grid[:track]
			@s_url  = grid[:track][:s_url]
			@s_filt = grid[:track][:s_filter]
		end
	end

	def update(rows:)
		@rows  = parse_rows(rows)
	end

	def build_order_link(column:, label:)
		ord_lnk = "?column=#{column}&direction="
		if column == session.dig(@s_filt, 'column')
			link_to(label, @s_url + ord_lnk + next_direction)
		else
			link_to(label, @s_url + ord_lnk + "#{column}&direction=asc")
		end
	end

	def sort_indicator
		tag.span(class: "sort sort-#{session[@s_filt]['direction']}")
	end

	private
		# parse header definition to set correct objects
		def parse_title(title)
			res = Array.new
			title.each { |item|
				case item[:kind]
				when "normal"
					item[:class] = "font-semibold border px py"
				when "inverse"
					item[:class] = "font-semibold bg-white text-indigo-900 border px py"
				when "gap"
					item[:value] = "&nbsp;"
				when "button"
					item[:value] = ButtonComponent.new(button: item[:button])
					item[:class] = "bg-white"
				when "dropdown"
					item[:value] = DropdownComponent.new(button: item[:button])
					item[:class] = "bg-white"
				end
				item[:align] = "left" unless item[:align]
				res << item
			}
			res
		end

		# parse row definitions to set correct objects
		# each row links to a url - buttons to specific url
		def parse_rows(rows)
			rows.each { |row|
				row[:data] = {} unless row[:data]
				row[:data][:turbo_frame] = (row[:frame]=="modal" ? "modal" : "_top")
			 	row[:classes] = ["hover:text-white", "hover:bg-blue-700"] unless row[:name]=="bottom"
					row[:items].each { |item|
					case item[:kind]
					when "normal", "lines", "icon", "location"
						item[:class] = "border px py"
					when "button"
						item[:class] = "bg-white" unless item[:button][:kind]=="location"
						item[:value] = ButtonComponent.new(button: item[:button])
					when "bottom"
						item[:align] = "center" unless item[:align]
						item[:class] = "text-indigo-900 font-semibold"
					when "percentage"
						item[:align] = "center" unless item[:align]
						item[:class] = "font-semibold border px py "
						if item[:value] # not nil
							case item[:value]
							when 0..25
								item[:class] = item[:class] + "text-red-900"
							when 26..50
								item[:class] = item[:class] + "text-yellow-700"
							when 51..75
								item[:class] = item[:class] + "text-gray-700"
							when 76..100
								item[:class] = item[:class] + "text-green-900"
							end
							item[:value] = number_to_percentage(item[:value], precision: 0)
						else
							item[:value] = ""
						end
					when "checkbox-q"
						item[:class] = "border px py"
						item[:align] = "center"
					end
					item[:align] = "left" unless item[:align]
				}
			}
			rows
		end

		def next_direction
			session[@s_filt]['direction'] == 'asc' ? 'desc' : 'asc'
		end
end
