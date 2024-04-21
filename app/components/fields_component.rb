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
# => "contact": mailto:, tel: and whatsapp: buttons for a person
# => "date-box": :key (field name), :value (date_field), :s_year (start_year)
# => "email-box": :key (field name), :value (email_field), :size (box size)
# => "gap": :size (count of &nbsp; to separate content)
# => "header-icon": :value (name of icon file in assets)
# => "hidden": :a hidden link for the form
# => "icon": :value (name of icon file in assets)
# => "icon-label": :icon (name of icon file), :label (added text)
# => "label": :value (semibold text string)
# => "label-checkbox": :key (attribute of checkbox), :value (added text)
# => "number-box": :key (field name), :value (number_field), size:
# => "password-box": :key (field name), :value (password_field)
# => "person-type": icons (& tips) for type of person in the database
# => "rich-text-area": :key (field name)
# => "select-box": :key (field name), :options (array of valid options), :value (form, select)
# => "select-collection": :key (field name), :collection, :value (form, select)
# => "search-text": :url (search_in), :value
# => "search-select": :key (search field), :url (search_in), :options, :value
# => "search-collection": :key (search field), :url (search_in), :options, :value
# => "search-box": :key (search field), :url (search_in), :options
# => "string": :value (regular text string)
# => "subtitle": :value (bold text of title)
# => "text-area": :key (field name), :value (text_field), :size (box size), lines: number of lines
# => "text-box": :key (field name), :value (text_field), :size (box size)
# => "time-box": :hour & :mins (field names)
# => "title": :value (bold text of title in orange colour)
class FieldsComponent < ApplicationComponent
	def initialize(fields:, form: nil)
		@fields = parse(fields)
		@form   = form
	end

	# render to html
	def call
		table_tag do
      @fields.map do |row|
        tablerow_tag do
          row.map { |field| render_field(field) }.join.html_safe
        end
      end.join.html_safe
    end
	end

	# wrapper to define the component's @form - whe required.
	def form=(formobj)
		@form = formobj
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
			row.each do |item|
				case item[:kind]	# need to adapt to each fields "kind"
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
				when "label-checkbox"
					item[:class] ||= "align-middle"
				when /^(search-.+)$/
					item[:value] = SearchBoxComponent.new(search: item)
				when "nested-form"
					item[:btn_add] ||= {kind: "add-nested"}
				when "gap", "label", "lines", "side-cell", "string", "subtitle", "title", "top-cell"
					set_text_field(item)
				when /^(select-.+|.+-box|.+-area)$/
					item[:class] ||= "align-top"
				when "person-type"
					set_person_type(item)
				else
					item[:i_class] = "rounded p-0" unless item[:kind]=="gap"
				end
				item[:align] ||= "left"
#				item[:class] = (item[:class].present? ? item[:class] + " " : "") + "border px py"
				res.last << item
			end
		end
		res
	end

	# wrapper to render a specific field
	def render_field(field)
    tablecell_tag(field) do
      case field[:kind]
      when /^(accordion|button|contact|dropdown|search-.+)$/
        render field[:value]
      when /^(select-.+|.+box|.+-area|hidden|radio.+|upload)$/
        render InputBoxComponent.new(field:, form: @form)
      when "gap"
        ("&nbsp;" * field[:size]).html_safe
      when "grid"
        render GridComponent.new(grid: field[:value], form: @form)
      when "header-icon", "icon", "icon-label"
        render_image_field(field)
      when "lines"
        field[:value].map { |line| "&nbsp;#{line}<br>" }.join.html_safe
      when "nested-form"
        render NestedComponent.new(model: field[:model], key: field[:key], form: @form, child: field[:child], row: field[:row], filter: field[:filter], btn_add: field[:btn_add])
      when "person-type"
        render_role_icons(field[:icons])
      else
        if field[:dclass]
					field[:value].tap { |value| break "<div class=\"#{field[:dclass]}\">#{value}</div>"}.html_safe
				else
					field[:value]
				end
      end
    end
  end

	# render an image field
	def render_image_field(item)
    html = ""
    if item[:label]
      html += "<div class=\"inline-flex items-center\">"
      html += "#{item[:label]}&nbsp;" if item[:right]
    end
    if item[:tip]
      html += "<button data-tooltip-target=\"tooltip-#{item[:tipid]}\" data-tooltip-placement=\"bottom\" type=\"button\">"
    end
    html += image_tag(item[:value] || item[:icon], size: item[:size], class: item[:class])
    if item[:tip]
      html += "</button>"
      html += "<div id=\"tooltip-#{item[:tipid]}\" role=\"tooltip\" class=\"absolute z-20 invisible inline-block px-1 py-1 text-sm font-medium text-gray-100 bg-gray-700 rounded-md shadow-sm opacity-0 tooltip\">"
      html += item[:tip]
      html += "</div>"
    end
    if item[:label]
      html += "&nbsp;#{item[:label]}" unless item[:right]
      html += "</div>"
    end
    html.html_safe
  end

  # render the icons/tooltips for rols attached to a user
	def render_role_icons(icons)
    icons.map do |icon|
      html = ""
      if icon[:tip]
        html += "<button data-tooltip-target=\"tooltip-#{icon[:tipid]}\" data-tooltip-placement=\"bottom\" type=\"button\">"
      end
      html += image_tag(icon[:img], size: "25x25")
      if icon[:tip]
        html += "</button>"
        html += "<div id=\"tooltip-#{icon[:tipid]}\" role=\"tooltip\" class=\"absolute z-10 invisible inline-block px py text-sm font-medium text-gray-100 bg-gray-700 rounded-md shadow-sm opacity-0 tooltip\">"
        html += icon[:tip]
        html += "</div>"
      end
      html
    end.join.html_safe
  end
	
	# wrapper to keep a person's available contact details in a single field.
	def set_contact(item)
		item[:value] = ContactComponent.new(website: item[:website], email: item[:email], phone: item[:phone], device: item[:device])
	end

	# used for all icon/image fields - except for "image-box"
	def set_icon(item)
		if item[:kind]=="header-icon"
			i_size         = "50x50"
			item[:align]   = "center"
			item[:class] ||= "align-center"
			item[:rows]    = 2 unless item[:rows]
		else
			i_size = "25x25"
			if item[:label] && item[:kind]!="icon-label"
				item[:class] ||= "align-top inline-flex"
			else
				item[:align] ||= "right"
			end
		end
		item[:size] = i_size unless item[:size]
	end

	# used for all text-like fields - except for inputboxes, of course
	def set_text_field(item)
		case item[:kind]
		when "gap"
			item[:size]  ||= 4
		when "label"
			l_cls          = "inline-flex align-top font-semibold"
			item[:class]   = item[:class] ? "#{item[:class]} #{l_cls}" : l_cls
		when "lines"
			item[:class] ||= "align-top border px py"
		when "side-cell"
			item[:align] ||= "right"
			item[:class]   = "align-center font-semibold text-indigo-900"
		when "string"
			item[:class] ||= "align-top"
		when "subtitle"
			item[:class]   = "align-top font-bold"
		when "title"
			item[:class]   = "align-top font-bold text-yellow-600"
		when "top-cell"
			item[:class]   = "font-semibold bg-indigo-900 text-gray-300 align-center border px py"
		end
	end

	# set icons for a person-type
	def set_person_type(item)
		item[:icons] = []
		item[:icons] << {img: "user.svg", tip: I18n.t("role.user"), tipid: "puser"} if item[:user]
		item[:icons] << {img: "player.svg", tip: I18n.t("role.player"), tipid: "pplayer"} if item[:player]
		item[:icons] << {img: "coach.svg", tip: I18n.t("role.coach"), tipid: "pcoach"} if item[:coach]
	end
end
