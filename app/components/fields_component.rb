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
# => "search-combo": :key (search field), :url (search_in), :options
# => "location": :icon (optional), :url (gmaps_url), :name (name to display)
# => "link": :icon (optional), :url (link_to_url), :label (label to display), frame:, replace: (pass turbo data?)
# => "jump": :icon (optional), :url (link_to_url in the site), :label (label to display), frame:, replace: (pass turbo data?)
# => "hidden": :a hidden link for the form
# => "gap": :size (count of &nbsp; to separate content)
class FieldsComponent < ApplicationComponent
	def initialize(fields:, form: nil)
		@fields = parse(fields)
		@form   = form
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
					item[:h_class] = "font-semibold text-left text-indigo-900"
					item[:t_class] = "font-semibold text-right text-indigo-900"
					item[:i_class] = "flex justify-between items-center p-1 w-full bg-gray-100 text-left text-gray-700 rounded-md hover:bg-gray-500 hover:text-indigo-100 focus:bg-indigo-900 focus:text-gray-200"
					i = 1
					item[:objects].each { |obj|
						obj[:head_id] = "accordion-collapse-heading-" + i.to_s
						obj[:body_id] = "accordion-collapse-body-" + i.to_s
						i = i +1
					}
				when "contact"
					item[:mail] = ButtonComponent.new(button: {kind: "email", value: item[:email]}) if (item[:email] and item[:email].length>0)
					if item[:phone] and item[:phone].length>0
						item[:call] = ButtonComponent.new(button: {kind: "call", value: item[:phone]})
						item[:whatsapp] = ButtonComponent.new(button: {kind: "whatsapp", value: item[:phone]})
					end
				when "gap"
					item[:size]  = 4 unless item[:size]
				when "header-icon"
					item[:align] = "center"
					item[:class] = item[:class] ? item[:class] + " align-top" : "align-top"
					item[:size]  = "50x50" unless item[:size]
					item[:rows]  = 2 unless item[:rows]
				when "icon"
					item[:align] = "right" unless item[:align]
					item[:class] = item[:class] ? item[:class] + " align-middle" : "align-middle"
					item[:size]  = "25x25" unless item[:size]
				when "icon-label"
					item[:size]  = "25x25" unless item[:size]
					item[:class] = "align-top inline-flex" unless item[:class]
				when "label", "label-checkbox"
					item[:class]   = item[:class] ? item[:class] + " inline-flex align-top font-semibold" : " inline-flex align-top font-semibold"
					item[:i_class] = "rounded bg-gray-200 text-blue-700"
				when "lines"
					item[:class] = "align-top border px py" unless item[:class]
				when "link"
					item[:class]   = item[:class] ? item[:class] : " inline-flex align-middle p-0 text-sm"
					item[:size]    = "20x20" unless item[:size]
				when "location"
					item[:class]   = "inline-flex align-top font-semibold"
					item[:i_class] = "rounded-md hover:bg-blue-100"
				when /^(search-.+)$/
					item[:align]   = "left" unless item[:align]
					item[:size]    = 16 unless item[:size]
					item[:lines]   = 1 unless item[:lines]
					item[:class]   = "inline-flex rounded-md border-2 border-gray-300"
					item[:i_class] = "block px-1 py-0 w-full text-gray-900 bg-gray-50 shadow-inner rounded border-1 border-gray-300 appearance-none focus:outline-none focus:ring-0 focus:border-blue-700 peer"
					item[:i_class] = item[:i_class] + ((item[:label] or item[:fields]) ? " mt-3" : " align-middle")
					item[:l_class] = "absolute text-md font-semibold text-gray-700 duration-300 transform -translate-y-4 scale-75 top-2 z-10 origin-[0] bg-transparent px-0 peer-focus:px-0 peer-focus:text-blue-700 peer-placeholder-shown:scale-100 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:top-1/2 peer-focus:top-2 peer-focus:scale-75 peer-focus:-translate-y-4 left-0"
					item[:fields]  = [{kind: item[:kind], key: item[:key].to_sym, label: item[:label], options: item[:options], value: item[:value]}] unless item[:kind] == "search-combo"
					item[:kind]    = "search-combo"
				when "side-cell"
					item[:align] = "right" unless item[:align]
					item[:class] = "align-center font-semibold text-indigo-900"
				when "string"
					item[:class] = "align-top"
				when "subtitle"
					item[:class] = "align-top font-bold"
				when "title"
					item[:class] = "align-top font-bold text-yellow-600"
				when "top-cell"
					item[:class] = "font-semibold bg-indigo-900 text-gray-300 align-center border px py"
				when "upload"
					item[:class] = "align-middle px py" unless item[:class]
					item[:i_class] = "inline-flex align-center rounded-md shadow bg-gray-100 ring-2 ring-gray-300 hover:bg-gray-300 focus:border-gray-300 font-semibold text-sm whitespace-nowrap px-1 py-1 m-1 max-h-6 max-w-6 align-center"
				when /^(select-.+|.+-box|.+-area)$/
					item[:i_class] = "rounded py-0 px-1 shadow-inner border-gray-200 bg-gray-50 focus:ring-blue-700 focus:border-blue-700"
					if item[:kind]=="number-box" or item[:kind]=="time-box"
						item[:i_class] = item[:i_class] + " text-right"
						item[:min]     = 0 unless item[:min]
						item[:max]     = 99 unless item[:max]
						item[:step]    = 1 unless item[:step]
					end
				else
					item[:i_class] = "rounded p-0" unless item[:kind]=="gap"
				end
				item[:align] = "left" unless item[:align]
				item[:cell]  = tablecell_tag(item)
				res.last << item
			end
		end
		res
	end
end
