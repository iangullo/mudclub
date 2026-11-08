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
	#-------------------------------------
	# CSS definitions
	#-------------------------------------

	# Everything clickable inside a dropdown shares these
	CTRL_BASE  = %w[items-center whitespace-nowrap rounded-md focus:outline-none].freeze
	CTRL_FOCUS = %w[focus:bg-blue-700 focus:text-white].freeze
	CTRL_HOVER = %w[hover:bg-blue-700 hover:text-white].freeze

	# Layout variations — the only thing that really differs
	MENU_LAYOUT = %w[inline-flex gap-2 font-semibold px-2 py-2 focus:ring-2 focus:ring-gray-200].freeze
	SUB_LAYOUT  = %w[flex w-full gap-2 px-2 py-1].freeze
	LINK_LAYOUT = %w[flex w-full gap-1 px-2 py-1 no-underline].freeze

	# Composed
	MENU_CLS = (MENU_LAYOUT + CTRL_BASE + CTRL_FOCUS + CTRL_HOVER).freeze
	SUB_CLS  = (SUB_LAYOUT  + CTRL_BASE + CTRL_FOCUS).freeze
	LINK_CLS = (LINK_LAYOUT + CTRL_BASE + CTRL_FOCUS + CTRL_HOVER).freeze

	# Sub-trigger wrapper carries the hover state (so the full row highlights)
	SUB_WRAPPER_CLS = (%w[relative block w-full rounded-md] + CTRL_HOVER).freeze

	# Menu containers — NO overflow-hidden (would clip submenus)
	MENU_DROP_CLS = %w[hidden absolute z-10 p-1 rounded-md bg-blue-900 text-gray-100 text-left].freeze
	DROP_CLS      = %w[hidden absolute z-10 p-1 rounded-md bg-gray-200 text-gray-500 text-left font-semibold].freeze

	ITEM_CLS = %w[block w-full].freeze

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

	# Where a SUB opens, given where its PARENT opens.
	# Rightward families keep opening right; right-anchored / leftward families
	# keep opening left. This is the whole "inheritance" rule.
	SUB_PLACE = {
			"bottom-start" => "right-start",
			"bottom-end"   => "left-start",
			"top-start"    => "right-start",
			"top-end"      => "left-start",
			"right-start"  => "right-start",
			"right-end"    => "right-start",
			"left-start"   => "left-start",
			"left-end"     => "left-start"
	}.freeze

	#-------------------------------------
	# Component standard methods
	#-------------------------------------

	def initialize(button)
		@button = parse(button)
		hashify_options(@button[:options]) if @button[:options]
		apply_symbol_defaults
	end

	def render?
		@button[:options].present? || @button[:url].present?
	end

	# --- helpers used by the template ---

	# True when this menu opens leftward (bottom-end, top-end, left-*).
	# Controls text alignment of leaf links and sub-trigger labels.
	def flipped?
		return @flipped if defined?(@flipped)
		@flipped = flipped_place?(@button[:place])
	end

	# :down for top-level menus (bottom-*/top-*), :left or :right for subs.
	def chevron_side
			p = @button[:place].to_s
			return :left  if p.start_with?("left")
			return :right if p.start_with?("right")
			:down
	end

	def link_classes
			flipped? ? (LINK_CLS + %w[justify-end]) : LINK_CLS
	end

	def wrapper_class
			if @button[:append]
					"relative inline-flex items-center"
			elsif @button[:sub]
					SUB_WRAPPER_CLS.join(" ")
			else
					"relative inline-block"
			end
	end

	#-------------------------------------
	# Component internal support methods
	#-------------------------------------
	private
		def apply_symbol_defaults
			sym = @button[:symbol]
			return unless sym.is_a?(Hash) && sym[:options].is_a?(Hash)
			sym[:options][:css] ||= @button[:i_class]
		end

		def flipped_place?(place)
			p = place.to_s
			p.end_with?("-end") || p.start_with?("left")
		end

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
				set_place(btn)
				set_class(btn)
			end
		end

		def set_name(button)
			button[:id] = "#{button[:name]}-btn"
			if button[:name] =~ /^(add.*)$/
				button[:title]  ||= I18n.t("action.create")
				button[:symbol] ||= { concept: "add", options: { css: "items-center" } }
			end
		end

		# Placement is decided here, once. Order of precedence:
		#   1. explicit `:place`             → trust the caller
		#   2. `:sub` with `:parent_place`   → derive from parent
		#   3. `:align == :right`            → bottom-end (top-level right menu)
		#   4. otherwise                     → bottom-start / right-start
		def set_place(button)
			button[:place] ||= if button[:sub] && button[:parent_place]
				SUB_PLACE[button[:parent_place].to_s] || "right-start"
			elsif button[:align].to_s == "right"
				"bottom-end"
			else
				button[:sub] ? "right-start" : "bottom-start"
			end
		end

		def set_class(button)
			button[:o_class] ||= ITEM_CLS.join(" ")
			case button[:kind].to_s
			when /^(add.*)$/    then set_add_class(button)
			when "link"         then set_link_class(button)
			when "menu"         then set_menu_class(button)
			end
			# Append placement classes (last, so they sit alongside d_class).
			button[:d_class] = [ button[:d_class], PLACE_CLASSES[button[:place]] ].compact.join(" ")
		end

		def set_add_class(button)
			button[:b_class] ||= "min-h-4 items-center rounded-md hover:bg-green-200 focus:bg-green-200 focus:ring-2 focus:ring-green-500"
			button[:d_class] ||= DROP_CLS.join(" ")
			button[:d_class] += " border border-green-500 m-2" if button[:border]
		end

		def set_link_class(button)
			button[:b_class] ||= (button[:class] || "inline-flex items-center rounded-md bg-gray-100 hover:bg-gray-300 focus:ring-gray-300 focus:ring-2 focus:border-gray-300 font-semibold whitespace-nowrap ml-1 p-0.5")
			button[:b_class] += " text-sm" if (button[:icon] || button[:symbol]) && !button[:append]
			button[:d_class] ||= DROP_CLS.join(" ")
			button[:d_class] += " border border-gray-500" if button[:border].present?
		end

		def set_menu_class(button)
			button[:b_class] ||= (button[:sub] ? SUB_CLS : MENU_CLS).join(" ")
			button[:d_class] ||= MENU_DROP_CLS.join(" ")
		end
end
