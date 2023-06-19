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

# FieldsComponent - ViewComponent to render rows of fields as table cells in a view
# managing different kinds of content for each field:
# => "button": a specific ButtonComponent - passed as argument item[:button]
# => "icon": :value (name of icon file in assets)
# => "header-icon": :value (name of icon file in assets)
# => "title": :value (bold text of title in orange colour)
# => "subtitle": :value (bold text of title)
# => "label": :value (semibold text string)
# => "string": :value (regular text string)
# => "icon-label": :icon (name of icon file), :label (added text)
# => "label-checkbox": :key (attribute of checkbox), :value (added text)
# => "text-box": :key (field name), :value (text_field), :size (box size)
# => "email-box": :key (field name), :value (email_field), :size (box size)
# => "password-box": :key (field name), :value (password_field)
# => "text-area": :key (field name), :value (text_field), :size (box size), lines: number of lines
# => "rich-text-area": :key (field name)
# => "number-box": :key (field name), :value (number_field), size:
# => "date-box": :key (field name), :value (date_field), :s_year (start_year)
# => "contact": mailto:, tel: and whatsapp: buttons for a person
# => "time-box": :hour & :min (field names)
# => "select-box": :key (field name), :options (array of valid options), :value (form, select)
# => "select-collection": :key (field name), :collection, :value (form, select)
# => "select-file": :key (field name), :icon, :label, :value (form, select)
# => "search-text": :url (search_in), :value
# => "search-select": :key (search field), :url (search_in), :options, :value
# => "search-collection": :key (search field), :url (search_in), :options, :value
# => "search-box": :key (search field), :url (search_in), :options
# => "hidden": :a hidden link for the form
# => "gap": :size (count of &nbsp; to separate content)
class FieldsComponent < ApplicationComponent
	def initialize(fields:, form: nil)
		@fields = parse(fields)
		@form   = form
	end

	def form=(formobj)
		@form = formobj
	end

	def render?
		@fields.present?
	end

	private
	def parse(fields)
		res = Array.new
		fields.each do |row|
			res << [] # new row n header
			row.each do |item|
				case item[:kind]
				when "accordion"
					item[:value] = AccordionComponent.new(accordion: item)
				when "button"	# item[:button] has to contain the button definition
					item[:value] = ButtonComponent.new(button: item[:button])
				when "contact"
					set_contact(item)
				when "dropdown"	# item[:button] has to contain the button definition
					item[:value] = DropdownComponent.new(button: item[:button])
				when "header-icon", "icon", "icon-label"
					set_icon(item)
				when /^(search-.+)$/
					item[:value] = SearchBoxComponent.new(search: item)
				when "nested-form"
					item[:btn_add] = {kind: "add-nested"} unless item[:btn_add]
				when "label", "label-checkbox", "lines", "side-cell", "string", "subtitle", "title", "top-cell"
					set_text_field(item)
				when "upload"
					item[:class] = "align-middle px py" unless item[:class]
					item[:i_class] = "inline-flex align-center rounded-md shadow bg-gray-100 ring-2 ring-gray-300 hover:bg-gray-300 focus:border-gray-300 font-semibold text-sm whitespace-nowrap px-1 py-1 m-1 max-h-6 max-w-6 align-center"
				when /^(select-.+|.+-box|.+-area)$/
					set_box(item)
				else
					item[:i_class] = "rounded p-0" unless item[:kind]=="gap"
				end
				item[:align] ||= "left"
				item[:cell]    = tablecell_tag(item)
				res.last << item
			end
		end
		res
	end

	def set_contact(item)
		item[:mail] = ButtonComponent.new(button: {kind: "email", value: item[:email]}) if (item[:email] and item[:email].length>0)
		if item[:phone] and item[:phone].length>0
			item[:call] = ButtonComponent.new(button: {kind: "call", value: item[:phone]}) if item[:device]=="mobile"
			item[:whatsapp] = ButtonComponent.new(button: {kind: "whatsapp", value: item[:phone], web: (item[:device]=="desktop")})
		end
	end

	def set_box(item)
		item[:class]   = "align-top" unless item[:class]
		item[:i_class] = "rounded py-0 px-1 shadow-inner border-gray-200 bg-gray-50 focus:ring-blue-700 focus:border-blue-700"
		bsize = (item[:kind]=="time-box") ? 5 : ((item[:options].present?) ? 10 : 20)
		if item[:kind]=="rich-text-area"	# correct rendering for trix editor
			item[:i_class] = "trix-content " + item[:i_class]
		elsif item[:options].present?	# check size
			item[:options].each { |opt| bsize = opt.to_s.length if opt.to_s.length > bsize }
		elsif item[:kind]=="number-box" or item[:kind]=="time-box"	# check limits
			item[:i_class] = item[:i_class] + " text-right"
			item[:min]     = 0 unless item[:min]
			item[:max]     = 99 unless item[:max]
			item[:step]    = 1 unless item[:step]
		end
		item[:size] = bsize - 3 unless item[:size]
	end

	def set_icon(item)
		if item[:kind]=="header-icon"
			i_size       = "50x50"
			item[:align] = "center"
			item[:class] = item[:class] ? item[:class] + " align-center" : "align-center"
			item[:rows]  = 2 unless item[:rows]
		else
			i_size = "25x25"
			if item[:label]
				item[:class] = "align-top inline-flex" unless item[:class]
			else
				item[:align] = "right" unless item[:align]
				item[:class] = item[:class] ? item[:class] + " align-middle" : "align-middle"
			end
		end
		item[:size] = i_size unless item[:size]
	end

	def set_text_field(item)
		case item[:kind]
		when "gap"
			item[:size]  ||= 4
		when "label", "label-checkbox"
			l_cls          = "inline-flex align-top font-semibold"
			item[:class]   = item[:class] ? "#{item[:class]} #{l_cls}" : l_cls
			item[:i_class] = "rounded bg-gray-200 text-blue-700"
		when "lines"
			item[:class] ||= "align-top border px py"
		when "side-cell"
			item[:align] ||= "right"
			item[:class]   = "align-center font-semibold text-indigo-900"
		when "string"
			item[:class]   = "align-top"
		when "subtitle"
			item[:class]   = "align-top font-bold"
		when "title"
			item[:class]   = "align-top font-bold text-yellow-600"
		when "top-cell"
			item[:class]   = "font-semibold bg-indigo-900 text-gray-300 align-center border px py"
		end
	end
end
