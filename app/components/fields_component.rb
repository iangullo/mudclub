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

# FieldsComponent - ViewComponent to compose rows of content fields as table
#		cells in a view managing different kinds of content for each field:
# => :accordion: a collapsible accordion element
# => :button: a specific ButtonComponent - passed as argument item[:button]
# => :contact: mailto:, tel: and whatsapp: buttons for a person
# => :date_box: :key (field name), :value (date_field), :s_year (start_year)
# => :dropdown: a DropdownComponent - passed as argument to the menu generator
# => :diagram: svgdata (diagram SVG data we are editing), :court (symbol for court background image)
# => :email_box: :key (field name), :value (email_field), :size (box size)
# => :gap: :size (count of &nbsp; to separate content)
# => :header_icon: :value (name of icon file in assets)
# => :hidden: :a hidden link for the form
# => :icon: :icon (name of icon file in assets)
# => :icon_label: :icon (name of icon file), :label (added text)
# => :image: :value (load an image file)
# => :label: :value (semibold text string)
# => :label_checkbox: :key (attribute of checkbox), :value (added text)
# => :lines: :value (array of text lines to be shown)
# => :number_box: :key (field name), :value (number_field), size:
# => :nested_form: :model, :key, :form: :child, :row, :filter to define a NestedFormComponent
# => :partial: :partial (html.erb partial template), :locals (hash of local variables)
# => :password_box: :key (field name), :value (password_field)
# => :person_type: icons (& tips) for type of person in the database
# => :rich_text_area: :key (field name)
# => :select_box: :key (field name), :options (array of valid options), :value (form, select)
# => :select_collection: :key (field name), :collection, :value (form, select)
# => :search_text: :url (search_in), :value
# => :search_select: :key (search field), :url (search_in), :options, :value
# => :search_collection: :key (search field), :url (search_in), :options, :value
# => :search_box: :key (search field), :url (search_in), :options
# => :separator: separator line (kind: :dashed, :solid, :dotted, rounded: )
# => :side_cell: :value (content stiyled like a TableComponent side_cell)
# => :steps: :steps, :court (responsive rendering of drill steps)
# => :string: :value (regular text string)
# => :subtitle: :value (bold text of title)
# => :svg: :value (raw svg content to show)
# => :symbol: :value (svg symbol to be rendered)
# => :table: :value (TableComponent definition), :form (optional)
# => :targets: array of {text_, status} pairs
# => :text_area: :key (field name), :value (text_field), :size (box size), lines: number of lines
# => :text_box: :key (field name), :value (text_field), :size (box size)
# => :time_box: :hour & :mins (field names)
# => :title: :value (bold text of title in orange colour)
# => :top_cell: :value (content styled like a TableComponent top_cell)
# => :upload: :label, :key (form binding for content), :value (file already assigned)
class FieldsComponent < ApplicationComponent
	def initialize(fields, form: nil)
		@form   = form
		@fields = parse(fields)
	end

	# render to html
	def call
		table_tag do
			@fields.map do |row|
				tablerow_tag do
					row.map { |field| render field }.join.html_safe
				end
			end.join.html_safe
		end
	end

	# wrapper to define the component's @form - whe required.
	def form=(formobj)
		@form = formobj
		@fields.each do |row|
			row.each do |field|
				field.form = formobj
			end
		end
	end

	def render?
		@fields.present?
	end

	private
	# parse all specified fields to set the correct rendering
	# parmeters for each.
	def parse(fields)
		res = Array.new
		fields.each do |row|
			res << [] # new row n header
			row.each do |field|
				res.last << FieldItemComponent.new(field, form: @form)
			end
		end
		res
	end
end
