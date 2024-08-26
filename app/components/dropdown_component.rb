# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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

# DropdownComponent - Viewcomponent buttons specific for muli-add and menu buttons
#  They have an :options array with :url,:icon:label
#  If :append is set, button with icon will be appended inline after a label.
class DropdownComponent < ApplicationComponent
	def initialize(button:)
		@button = parse(button)
	end
=begin
	def call
		if @button[:append]
			content_tag(:div, class: "inline-flex items-center") do
				concat(@button[:label].to_s)
				concat(render_button)
			end
		else
			concat(render_button)
		end
	end
=end
	def render?
		@button.present?
	end

	private

	def parse(button)
		button.tap do |btn|
			set_name(btn)
			set_class(btn)
			btn[:place] = (btn[:sub] ? "right-end" : "bottom")
		end
	end

	def render_button
		button_tag(
			id: @button[:id],
			class: @button[:b_class],
			type: "button",
			data: {
				dropdown_toggle: @button[:name],
				dropdown_placement: @button[:place],
				dropdown_offset_distance: 10,
				dropdown_offset_skidding: 10
			}
		) do
			if @button[:ham]
				concat('<svg class="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" /></svg>'.html_safe)
			elsif @button[:icon]
				concat(image_tag(@button[:icon], size: @button[:size] || "25x25", class: @button[:i_class]))
			end

			if @button[:label] && !@button[:append]
				content_tag(:div, class: "inline-flex items-center") do
					concat(@button[:label].to_s)
					if @button[:sub]
						concat('<svg aria-hidden="true" class="w-4 h-4 ml-3" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"></path></svg>'.html_safe)
					else
						concat('<svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>'.html_safe)
					end
				end
			end
			content_tag(:div, id: @button[:name], class: @button[:d_class]) do
				content_tag(:ul, aria: { labelledby: @button[:id] }) do
					@button[:options]&.each do |option|
						content_tag(:li, class: @button[:o_class]) do
							if option[:options]
								option[:id] = "btn#{option[:name]}"
								option[:sub] = true
								render(DropdownComponent.new(button: option))
							else
								link_to(option[:url], data: option[:data]) do
									image_tag(option[:icon], size: option[:size] ? option[:size] : "25x25") if option[:icon]
									option[:label] || ''.to_s
								end
							end
						end
					end
				end
			end
		end
	end


	def set_name(button)
		button[:id] = "#{button[:name]}-btn"
		button[:icon] = "add.svg" if button[:name] =~ /^(add.*)$/
	end

	def set_class(button)
		case button[:kind]
		when /^(add.*)$/
			set_add_class(button)
		when "link"
			set_link_class(button)
		when "menu"
			set_menu_class(button)
		end
	end

	def set_add_class(button)
		button[:b_class] ||= "max-h-6 min-h-4 align-center rounded-md hover:bg-green-200 focus:bg-green-200 focus:ring-2 focus:ring-green-500"
		button[:d_class] ||= "hidden rounded-md bg-gray-100 text-gray-500 text-left font-semibold overflow-hidden no-underline z-10"
		button[:d_class] += " border border-green-500" if button[:border].present?
		button[:o_class] ||= "rounded-md hover:bg-blue-700 hover:text-white whitespace-nowrap no-underline block m-0 pl-1 pr-1"
	end

	def set_link_class(button)
		button[:b_class] ||= (button[:class] || "inline-flex align-center rounded-md bg-gray-100 hover:bg-gray-300 focus:ring-gray-300 focus:ring-2 focus:border-gray-300 font-semibold whitespace-nowrap px-1 py-1 m-1")
		button[:b_class] += " text-sm" if button[:icon] && !button[:append]
		button[:d_class] ||= "hidden rounded-md bg-gray-100 text-gray-500 text-left font-semibold overflow-hidden no-underline z-10"
		button[:d_class] += " border border-gray-500" if button[:border].present?
		button[:o_class] ||= "rounded-md hover:bg-blue-700 hover:text-white whitespace-nowrap no-underline block m-0 pl-1 pr-1"
	end

	def set_menu_class(button)
		button[:b_class] ||= (button[:sub] ? "inline-flex items-center" : "rounded-md hover:bg-blue-700 hover:text-white focus:bg-blue-700 focus:text-white focus:ring-2 focus:ring-gray-200 whitespace-nowrap rounded ml-2 px-2 py-2 font-semibold")
		button[:d_class] ||= "hidden rounded-md bg-blue-900"
		button[:o_class] ||= "rounded-md hover:bg-blue-700 hover:text-white whitespace-nowrap no-underline block m-0 pl-2 pr-2 py-2"
	end
end
