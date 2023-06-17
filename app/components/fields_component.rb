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
# => "dropdown": A DropDownComponent definition
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
# => "time-box": :hour & :min (field names)
# => "select-box": :key (field name), :options (array of valid options), :value (form, select)
# => "select-collection": :key (field name), :collection, :value (form, select)
# => "select-file": :key (field name), :icon, :label, :value (form, select)
# => "search-text": :url (search_in), :value
# => "search-select": :key (search field), :url (search_in), :options, :value
# => "search-collection": :key (search field), :url (search_in), :options, :value
# => "search-combo": :key (search field), :url (search_in), :options
# => "hidden": :a hidden link for the form
# => "gap": :size (count of &nbsp; to separate content)
#
# including the Field definitions
Dir.glob(File.expand_path('fields/*.rb', __dir__)).each { |file| require file }

class FieldsComponent < ApplicationComponent
	def initialize(fields:, form: nil, session: nil)
		@form    = form
		@session = session
		@fields  = parse(fields)
	end

	def form=(formobj)
		@form = formobj
		@fields.each do |field_row|
			field_row.each { |field| field&.form = formobj }
		end
	end

	def render?
		@fields.present?
	end

	private
	# parse field definitions and create the necessary objects
	def parse(fields)
		res = []
		fields.each do |row|
			fields_row = [] # new row of fields to render
			row.each do |item|
				case item[:kind]
				when "accordion"
					field = AccordionField.new(item)
				when /^(.*button)$/	# item[:button] has to contain the button definition
					field = ButtonField.new(item, @form)
				when "grid"
					field = GridField.new(item, @form, @session)
				when "header-icon", "icon", "icon-label", "image"
					field = ImageField.new(item)
				when "gap", "label", "lines", "side-cell", "string", "subtitle", "title", "top-cell"
					field = TextField.new(item)
				when "nested-form"
					field = NestedField.new(item, @form)
				when /^(select-.+|.+-box|.+-area|hidden|label-checkbox)$/
					field = InputBoxField.new(item, @form, @session)
				when /^(search-.+)$/
					field = SearchField.new(item, @session)
				end
				fields_row << field if field
			end
			res << fields_row
		end
		res
	end
end
