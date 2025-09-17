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

# FieldItemComponent - ViewComponent to produce items within a FieldsComponent
#		kinds of content for each FieldItem:
# => :accordion: a collapsible accordion element
# => :button: a specific ButtonComponent - passed as argument field[:button]
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
class FieldItemComponent < ApplicationComponent
	def initialize(field, form: nil)
		@field = parse_field(field)
		@form  = form
	end

	def call
		# field_item_tag do
		tablecell_tag(@field) do
			render_field_content
		end
	end

	def form=(formobj)
		@form = formobj
		@field[:content].form = formobj if @field[:content]&.respond_to?(:form)
	end

	private

	def field_align(align)
		case align.to_sym
		when :center, :middle
			"justify-center"
		when :right, :end
			"justify-end text-right"
		else
			"justify-start text-left"
		end
	end

	def field_css(field)
		d_class  = field[:class].to_s.split(" ")
		d_class << "w-full" if [ :accordion, :diagram, :table, :rich_text_area, :steps, :svg ].include?(field[:kind])
		d_class << field_align(field[:align]) if field[:align].present?
		d_class << "md:col-span-#{field[:cols]}" if field[:cols].present?
		d_class << "md:row-span-#{field[:rows]}" if field[:rows].present? && field[:kind] != :table
		field[:class] = d_class.compact.join(" ") if d_class.present?
	end

	def field_item_tag(&block)
		content_tag(:div, class: @field[:class], data: @field[:data], &block)
	end

	def parse_field(field)
		case field[:kind].to_s	# need to adapt to each fields "kind"
		when "accordion"
			field[:content] = AccordionComponent.new(title: field[:title], tail: field[:tail], objects: field[:objects])
		when "button"	# field[:button] has to contain the button definition
			field[:content] = ButtonComponent.new(**field[:button])
		when "contact"
			field[:content] = ContactComponent.new(website: field[:website], email: field[:email], phone: field[:phone], device: field[:device])
		when "diagram"
			field[:content] = DiagramComponent.new(court: field[:court], svgdata: field[:svgdata], css: field[:css])
		when "dropdown"	# field[:button] has to contain the button definition
			field[:content] = DropdownComponent.new(field[:button])
		when /^(.*icon.*|image)$/
			set_image(field)
		when "label_checkbox"
			field[:class] ||= " align-middle rounded-md"
		when /^(search_.+)$/
			field[:content] = SearchBoxComponent.new(field)
		when "gap", "label", "lines", "side_cell", "string", "subtitle", "title", "top_cell"
			set_text_field(field)
		when "partial"
			field[:content] = PartialComponent.new(partial: field[:partial], locals: field[:locals] || {})
		when /^(select_.+|.+box|.+_area)$/
			field[:class] ||= "align-top"
		when "separator"
			field[:stroke] ||= "solid"
		when "steps"
			field[:content] = StepsComponent.new(steps: field[:steps], court: field[:court])
		when "symbol"
			hashify_symbol(field)
			field[:content] = SymbolComponent.new(field[:symbol][:concept], **field[:symbol][:options])
		else
			field[:i_class] = "rounded p-0" unless field[:kind] == :gap
		end
		field[:align] ||= "left"
		field_css(field)
		field
	end

	def render_field_content
		case @field[:kind].to_s
		when /^(accordion|button|contact|diagram.*|dropdown|search_.+|partial|steps|svg|symbol)$/
			render @field[:content]
		when /^(select_.+|.+box|.+_area|hidden|radio.+|upload)$/
			render InputBoxComponent.new(@field, form: @form)
		when "gap"
			("&nbsp;" * @field[:size]).html_safe
		when /^(.*icon.*|image)$/
			render_image_field
		when "lines"
			@field[:value].map { |line| "&nbsp;#{line}<br>" }.join.html_safe
		when "nested_form"
			render NestedComponent.new(model: @field[:model], key: @field[:key], form: @form, child: @field[:child], row: @field[:row], filter: @field[:filter])
		when "roles"
			@field[:symbols].each { |symbol| concat(render_image(symbol)) }
		when "separator"
			("<hr class=\"#{@field[:stroke]}\"").html_safe
		when "table"
			render TableComponent.new(@field[:value], align: @field[:align], form: @form)
		when "targets"
			render_targets_field
		else
			if @field[:dclass]
				concat((@field[:value].tap { |value| break "<div class=\"#{@field[:dclass]}\">#{value}</div>" }.html_safe))
			else
				concat(@field[:value])
			end
		end
	end

	# render an image field
	def render_image_field
		html = ""
		if @field[:label]
			html += "<div class=\"inline-flex items-center\">"
			html += "#{@field[:label]}&nbsp;" if @field[:right]
		end
		html += render_image(@field)
		if @field[:label]
			html += "&nbsp;#{@field[:label]}" unless @field[:right]
			html += "</div>"
		end
		html.html_safe
	end

	# Add this private method to FieldsComponent
	def render_targets_field
		html = ""
		last = @field[:targets]&.last
		@field[:targets]&.each do |target|
			html += "<div class=\"inline-flex items-center space-x-2 py-1\">"
			html += render(TrafficLightComponent.new(status: target[:status])) unless @form
			html += "<span>#{target[:text]}</span>"
			html += render(InputBoxComponent.new({ kind: :number_box, max: 100, step: 1, value: target[:completion] })) if @form
			html += "</div>"
			html += "<br>" unless target == last
		end
		html.html_safe
	end

	# used for all icon/image fields - except for :image_box
	def set_image(field)
		case field[:kind]
		when :header_icon
			field[:size]  ||= "50x50"
			field[:align]   = "center"
			field[:class] ||= "align-top"
			field[:css]   ||= "max-w-75 max-h-100 rounded align-top m-1"
			field[:rows]    = 2 unless field[:rows]
		when :icon, :icon_label
			field[:size]  ||= "25x25"
			if field[:label] && field[:kind] == :icon
				field[:class] ||= "align-top inline-flex"
			else
				field[:align] ||= "right"
			end
		when :image
			field[:css] ||= "rounded align-top m-1"
		end
		if field[:symbol].present?	# symbol definition
			hashify_symbol(field)	# ensure it is a hash
			field[:content] = SymbolComponent.new(field[:symbol][:concept], **field[:symbol][:options])
		else
			field[:i_class] ||= field[:css]
		end
	end

	# used for all text-like fields - except for inputboxes, of course
	def set_text_field(field)
		case field[:kind]
		when :gap
			field[:size]  ||= 4
		when :label
			l_cls          = "inline-flex font-semibold"
			field[:class]   = field[:class] ? "#{field[:class]} #{l_cls}" : l_cls
		when :lines
			field[:class] ||= "align-top border px py"
		when :side_cell
			field[:align] ||= "right"
			field[:class]   = "align-center font-semibold text-indigo-900"
		when :string
			field[:class] ||= "align-top"
		when :subtitle
			field[:class]   = "align-top font-bold"
		when :title
			field[:class]   = "align-top font-bold text-yellow-600"
		when :top_cell
			field[:class]   = "font-semibold bg-indigo-900 text-gray-300 align-center border px py"
		end
	end
end
