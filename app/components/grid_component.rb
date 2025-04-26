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
# frozen_string_literal: true

# GridComponent - manage data grids as ViewComponent
# Each grid has two parts:
#   => title items:
#      => kind: :normal | :inverse | :gap | :button
#      => value: associated text
#      => class: optional (unrequired?)
#   => row items: have optional links in them (per row)
#   => data: data for the stimulus controller (optional)
# optional:
#   => form: form object (if needed)
#   => controller: stimulus controller for dynamic view updates
class GridComponent < ApplicationComponent
	attr_writer :form

	def initialize(grid, form: nil, controller: nil, align: "center")
		if controller	# add stimulus controller and data
			@controller = controller
			@data       = grid[:data].merge(action: "change->#{controller}#update")
		end
		@align  = align || "center"
		@form   = form
		@title  = parse_title(grid[:title])
		@rows   = parse_rows(grid[:rows])
		if grid[:track]
			@s_url  = grid[:track][:s_url]
			@s_filt = grid[:track][:s_filter]
		end
	end

	def build_order_link(column:, label:)
		ord_lnk = "?column=#{column}&direction="
		if column == session.dig(@s_filt, 'column')
			link_to(label, @s_url + ord_lnk + next_direction)
		else
			link_to(label, @s_url + ord_lnk + "#{column}&direction=asc")
		end
	end

	def call	# render into HTML
		content_tag(:div, align: @align) do
			table_tag(controller: @controller, data: @data) do
				concat(render_header)
				render_body
			end
		end
	end

	def sort_indicator
		tag.span(class: "sort sort-#{session[@s_filt]['direction']}")
	end

	def update(rows:)
		@rows  = parse_rows(rows)
	end

	private
		# track the ordering direction for trackable columns
		def next_direction
			session[@s_filt]['direction'] == 'asc' ? 'desc' : 'asc'
		end

		# parse header definition to set correct objects
		def parse_title(title)
			res = Array.new
			title.each { |item|
				case item[:kind]
				when :normal
					item[:class] = "font-semibold border px py"
				when :inverse
					item[:class] = "font-semibold bg-white text-indigo-900 border px py"
				when :gap
					item[:value] = "&nbsp;"
				when :button
					item[:value] = ButtonComponent.new(**item[:button])
					item[:class] = "bg-white"
				when :dropdown
					item[:value] = DropdownComponent.new(item[:button])
					item[:class] = "bg-white"
				end
				item[:align] = "left" unless item[:align]
				res << item
			}
			res
		end

		# parse row definitions to set correct objects
		# each row links to a url - buttons to specific url if specifed
		def parse_rows(rows)
			rows.each { |row|
				row[:data] ||= {}
				row[:data][:turbo_frame] = (row[:frame]=="modal" ? "modal" : "_top") if row[:url]
				row[:data]["#{@controller}-target"] = "player" if @controller
				row[:classes] ||= []
			 	row[:classes]  += ["hover:text-white", "hover:bg-blue-700"] unless row[:name]==:bottom
					row[:items].each { |item|
					case item[:kind]
					when :normal, :lines, :icon, :location, :text
						item[:class] ||= "border px py"
					when :button
						item[:class] ||= "bg-white" unless item[:button][:kind] == :location
						item[:value]   = ButtonComponent.new(**item[:button])
					when :bottom
						item[:align] ||= "center"
						item[:class]   = "text-indigo-900 font-semibold"
					when :checkbox_q
						@rowcue      ||= true if @controller
						item[:align]   = "center"
						item[:class] ||= "border px py"
					when :contact
						item[:align]   = "center"
						item[:class] ||= "border px py"
						item[:value]   = ContactComponent.new(email: item[:email], phone: item[:phone], device: item[:device])
					when :percentage
						item[:align] ||= "center"
						item[:class] ||= "font-semibold border px py"
						if item[:value] # not nil
							case item[:value]
							when 0..25
								item[:class] += " text-red-900"
							when 26..50
								item[:class] += " text-yellow-700"
							when 51..75
								item[:class] += " text-gray-700"
							when 76..100
								item[:class] += " text-green-900"
							end
							item[:value] = number_to_percentage(item[:value], precision: 0)
						else
							item[:value] = ""
						end
					end
					item[:align] ||= "left"
				}
			}
			rows
		end
		
		def render_body
			concat(content_tag(:tbody) do
				@rows.map { |g_row| render_row(g_row) }.join.html_safe
			end)
		end
		
		def render_cell(item, url, data)
			tablecell_tag(item) do
				case item[:kind]
				when :bottom, :gap, :percentage, :text
					item[:value]
				when :checkbox_q
					render_checkbox(item)
				when :icon
					render_icon(item, url, data)
				when :lines
					item[:value].map { |cad| link_to(cad, url, data:) }.join("<br>").html_safe
				when :normal
					link_to(item[:value].to_s, url, data:)
				when :number_box
					render(InputBoxComponent.new(item, form: @form))
				else
					render(item[:value])
				end
			end
		end
		
		def render_checkbox(item)
			content_tag(:div, class: "align-middle") do
				check_box(item[:key], "#{item[:player_id]}_#{item[:q]}", {
					checked: item[:value] == 1,
					class: "rounded bg-gray-200 text-blue-700",
					data: {
						target: "grid.checkbox",
						rowId: item[:player_id],
						columnId: item[:q]
					}
				})
			end
		end

		# render the GridComponent header
		def render_header
			content_tag(:thead, class: "bg-indigo-900 text-gray-300") do
				content_tag(:tr) do
					@title.map do |item|
						tablecell_tag(item, tag: :th) do
							case item[:kind]
							when :normal, :inverse, :gap
								concat(render_sort_indicator(item))
								concat(render_order_link(item))
							when :lines
								concat(item[:value].map { |line| line_tag(line) }.join.html_safe)
							when :dropdown, :button
								concat(render(item[:value]))
							end
						end
					end.join.html_safe
				end
			end
		end

		def render_icon(item, url, data)
			link_to(url, data:) do
				image_tag(item[:value], size: "25x25")
			end
		end

		def render_order_link(item)
			if item[:order_by]
				build_order_link(column: item[:order_by], label: item[:value])
			else
				item[:value]
			end
		end
		
		def render_row(g_row)
			tablerow_tag(data: g_row[:data], classes: g_row[:classes]) do
				g_row[:items].map { |item| render_cell(item, g_row[:url], g_row[:data]) }.join.html_safe
			end
		end

		def render_sort_indicator(item)
			sort_indicator if item[:sort]
		end
end
