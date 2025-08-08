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

# DropdownComponent - Viewcomponent buttons specific for muli-add and menu buttons
#  They have an :options array with :url, optional :label, :icon/:symbol
#  If :append is set, button with icon/symbol will be appended inline after a label.
class DropdownComponent < ApplicationComponent
	MIN_CLS  = %w[inline-flex items-center].freeze
	BTN_CLS  = MIN_CLS + %w[whitespace-nowrap rounded-md].freeze
	MENU_CLS = BTN_CLS + %w[p-2 font-semibold hover:bg-blue-700 hover:text-white focus:outline-none focus:ring-2 focus:ring-gray-200].freeze
	DROP_CLS = %w[hidden z-10 overflow-hidden rounded-md bg-gray-200 text-gray-500 text-left font-semibold].freeze
	ITEM_CLS = %w[block m-0 p-1 rounded-md hover:bg-blue-700 hover:text-white no-underline].freeze
	
	def initialize(button)
		@button = parse(button)
		if @button[:symbol] && @button[:symbol][:options]
			@button[:symbol][:options][:css] = @button[:i_class]
		end
	end

	def render?
		@button.present?
	end

	private

	def parse(button)
		hashify_symbol(button)
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
			elsif @button[:symbol] || @button[:icon]
				concat(render_image(@button))
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
								render(DropdownComponent.new(option))
							else
								link_to(option[:url], data: option[:data]) do
									render_image(option) if option[:symbol]
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
		if button[:name] =~ /^(add.*)$/
			button[:symbol] ||= {concept:"add", options: {css: "items-center"}}
		end
	end

	def set_class(button)
		button[:o_class] ||= ITEM_CLS.join(' ')
		case button[:kind].to_s
		when /^(add.*)$/
			set_add_class(button)
		when "link"
			set_link_class(button)
		when "menu"
			set_menu_class(button)
		end
	end

	def set_add_class(button)
		button[:b_class] ||= "min-h-4 items-center rounded-md hover:bg-green-200 focus:bg-green-200 focus:ring-2 focus:ring-green-500"
		button[:d_class] ||= DROP_CLS.join(' ')
		if button[:border]
			button[:d_class] += " border border-green-500 m-2"
		end
	end

	def set_link_class(button)
		button[:b_class] ||= (button[:class] || "inline-flex items-center rounded-md bg-gray-100 hover:bg-gray-300 focus:ring-gray-300 focus:ring-2 focus:border-gray-300 font-semibold whitespace-nowrap px-1 py-1 m-1")
		if (button[:icon] || button[:symbol]) && !button[:append]
			button[:b_class] += " text-sm"
		end
		button[:d_class] ||= DROP_CLS.join(' ')
		button[:d_class] += " border border-gray-500" if button[:border].present?
	end

	def set_menu_class(button)
		base = button[:sub] ? MIN_CLS : MENU_CLS
		button[:b_class] ||= base.join(' ')
		button[:d_class] ||= "hidden rounded-md bg-blue-900"
	end
end
