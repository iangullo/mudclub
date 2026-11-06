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
# frozen_string_literal: true

# DropdownComponent - Viewcomponent buttons specific for muli-add and menu buttons
#  They have an :options array with :url, optional :label, :icon/:symbol
#  If :append is set, button with icon/symbol will be appended inline after a label.
class DropdownComponent < ApplicationComponent
	MIN_CLS  = %w[inline-flex items-center px-2 py-1].freeze
	BTN_CLS  = MIN_CLS + %w[whitespace-nowrap rounded-md].freeze
	MENU_CLS = BTN_CLS + %w[px-2 py-1.5 font-semibold hover:bg-blue-700 hover:text-white focus:outline-none focus:ring-2 focus:ring-gray-200].freeze
	DROP_CLS = %w[hidden absolute z-10 overflow-hidden rounded-md bg-gray-200 text-gray-500 text-left font-semibold].freeze
	ITEM_CLS = %w[block].freeze
	LINK_CLS = %w[flex items-center gap-1 whitespace-nowrap px-2 py-1 rounded-md hover:bg-blue-700 hover:text-white no-underline].freeze

	# Static positioning for the absolute menu, keyed by the :place symbol
	# previously consumed by Flowbite. Tailwind: 2.5 = 10px = old offset-distance.
	PLACE_CLASSES = {
		"bottom-start" => "top-full left-0 mt-1",
		"bottom-end"   => "top-full right-0 mt-2",
		"top-start"    => "bottom-full left-0 mb-1",
		"top-end"      => "bottom-full right-0 mb-2",
		"right-start"  => "left-full top-0 ml-1",
		"right-end"    => "left-full bottom-0 ml-2",
		"left-start"   => "right-full top-0 mr-1",
		"left-end"     => "right-full bottom-0 mr-2"
	}.freeze

	def initialize(button)
		@button = parse(button)
		hashify_options(@button[:options]) if @button[:options]
		if @button[:symbol] && @button[:symbol][:options]
			@button[:symbol][:options][:css] ||= @button[:i_class]
		end
	end

	def render?
		@button.present?
	end

	private
		def hashify_options(options)
			options.each do |opt|
				hashify_symbol(opt)
				hashify_options(opt[:options]) if opt[:options]
			end
		end

		def parse(button)
			hashify_symbol(button)
			button.tap do |btn|
				set_name(btn)
				set_class(btn)
				btn[:place] = (btn[:sub] ? "right-start" : "bottom-start")
				set_placement(btn)
			end
		end

		def set_name(button)
			button[:id] = "#{button[:name]}-btn"
			if button[:name] =~ /^(add.*)$/
				button[:title]  ||= I18n.t("action.create")
				button[:symbol] ||= { concept: "add", options: { css: "items-center" } }
			end
		end

		def set_class(button)
			button[:o_class] ||= ITEM_CLS.join(" ")
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
			button[:d_class] ||= DROP_CLS.join(" ")
			if button[:border]
				button[:d_class] += " border border-green-500 m-2"
			end
		end

		def set_link_class(button)
			button[:b_class] ||= (button[:class] || "inline-flex items-center rounded-md bg-gray-100 hover:bg-gray-300 focus:ring-gray-300 focus:ring-2 focus:border-gray-300 font-semibold whitespace-nowrap px-1 py-1 m-1")
			if (button[:icon] || button[:symbol]) && !button[:append]
				button[:b_class] += " text-sm"
			end
			button[:d_class] ||= DROP_CLS.join(" ")
			button[:d_class] += " border border-gray-500" if button[:border].present?
		end

		def set_menu_class(button)
			base = button[:sub] ? MIN_CLS : MENU_CLS
			button[:b_class] ||= base.join(" ")
			# NOTE: `absolute` added — without it the :place classes are no-ops
			# and the menu would flow inline now that Flowbite is not positioning it.
			button[:d_class] ||= "hidden absolute rounded-md bg-blue-900"
		end

		def set_placement(button)
			button[:d_class] ||= "hidden absolute"   # ← add this line
			button[:d_class] = [ button[:d_class], PLACE_CLASSES[button[:place]] ].compact.join(" ")
		end
end
