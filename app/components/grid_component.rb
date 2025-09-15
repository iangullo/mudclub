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

# GridComponent - ViewComponent to compose responsive flexbox grids with
#		different kinds of content for each item to be shown received as an
#		array of rows and content type hashes:
# => :accordion: a collapsible accordion element
# => :button: a specific ButtonComponent - passed as argument item[:button]
# => :contact: mailto:, tel: and whatsapp: buttons for a person
# => :date_box: :key (item name), :value (date_field), :s_year (start_year)
# => :dropdown: a DropdownComponent - passed as argument to the menu generator
# => :diagram: svgdata (diagram SVG data we are editing), :court (symbol for court background image)
# => :email_box: :key (item name), :value (email_field), :size (box size)
# => :gap: :size (count of &nbsp; to separate content)
# => :grid: :flow, :items (recursive GridComponent)
# => :header_icon: :value (name of icon file in assets)
# => :hidden: :a hidden link for the form
# => :icon: :icon (name of icon file in assets)
# => :icon_label: :icon (name of icon file), :label (added text)
# => :image: :value (load an image file)
# => :label: :value (semibold text string)
# => :label_checkbox: :key (attribute of checkbox), :value (added text)
# => :lines: :value (array of text lines to be shown)
# => :number_box: :key (item name), :value (number_field), size:
# => :nested_form: :model, :key, :form: :child, :row, :filter to define a NestedFormComponent
# => :partial: :partial (html.erb partial template), :locals (hash of local variables)
# => :password_box: :key (item name), :value (password_field)
# => :person_type: icons (& tips) for type of person in the database
# => :rich_text_area: :key (item name)
# => :select_box: :key (item name), :options (array of valid options), :value (form, select)
# => :select_collection: :key (item name), :collection, :value (form, select)
# => :search_text: :url (search_in), :value
# => :search_select: :key (search item), :url (search_in), :options, :value
# => :search_collection: :key (search item), :url (search_in), :options, :value
# => :search_box: :key (search item), :url (search_in), :options
# => :separator: separator line (kind: :dashed, :solid, :dotted, rounded: )
# => :side_cell: :value (content stiyled like a TableComponent side_cell)
# => :steps: :steps, :court (responsive rendering of drill steps)
# => :string: :value (regular text string)
# => :subtitle: :value (bold text of title)
# => :svg: :value (raw svg content to show)
# => :symbol: :value (svg symbol to be rendered)
# => :table: :value (TableComponent definition), :form (optional)
# => :targets: array of {text_, status} pairs
# => :text_area: :key (item name), :value (text_field), :size (box size), lines: number of lines
# => :text_box: :key (item name), :value (text_field), :size (box size)
# => :time_box: :hour & :mins (item names)
# => :title: :value (bold text of title in orange colour)
# => :top_cell: :value (content styled like a TableComponent top_cell)
# => :upload: :label, :key (form binding for content), :value (file already assigned)
class GridComponent < ApplicationComponent
	def initialize(rows, flow: :rows, form: nil)
		@rows  = parse_rows(rows)
		@form  = form
	end

	# render to html
	def call
		grid_container_tag do
			@rows.map do |row|
				grid_row_tag do
					row.map { |item| render_item(item) }.join.html_safe
				end
			end.join.html_safe
		end
	end

	# wrapper to define the component's @form - whe required.
	def form=(formobj)
		@form = formobj
		@items.each do |col|
			col.each do |item|
				item[:content].form = formobj if item[:content]&.respond_to?(:form)
			end
		end
	end

	def render?
		@rows.present?
	end

	private
	# wrappers to generate different html tags - self-explanatory
	def grid_container_tag(&block)
		g_class  = "min-w-max grid grid-cols-1 gap-2 md:gap-0"
		content_tag(:div, class: g_class, &block)
	end

	def grid_row_tag(&block)
		r_class  = "grid grid-cols-#{@cols} gap-1 md:gap-2 p-1"
		content_tag(:div, class: r_class, &block)
	end

	def grid_item_tag(item, &block)
		content_tag(:div, class: item[:class], data: item[:data], &block)
	end

	def grid_item_align(align)
		case align.to_sym
		when :center, :middle
			"justify-center"
		when :right, :end
			"justify-end"
		else
			"justify-start"
		end
	end

	def grid_item_css(item)
		c_class  = item[:class].to_s.split(" ")
		c_class << grid_item_align(item[:align]) if item[:align].present?
		c_class << "col-span-#{item[:cols]}" if item[:cols].present?
		c_class << "row-span-#{item[:rows]}" if item[:rows].present? && item[:kind] != :table
		item[:class] = c_class.join(" ") if c_class.present?
	end

	# parse one specific item to prepare it for rendering
	def parse_item(item)
		case item[:kind].to_s	# need to adapt to each items "kind"
		when "accordion"
			item[:content] = AccordionComponent.new(title: item[:title], tail: item[:tail], objects: item[:objects])
		when "button"	# item[:button] has to contain the button definition
			item[:content] = ButtonComponent.new(**item[:button])
		when "contact"
			set_contact(item)
		when "diagram"
			item[:content] = DiagramComponent.new(court: item[:court], svgdata: item[:svgdata], css: item[:css])
		when "dropdown"	# item[:button] has to contain the button definition
			item[:content] = DropdownComponent.new(item[:button])
		when /^(.*icon.*|image)$/
			set_image(item)
		when "label_checkbox"
			item[:class] ||= " align-middle rounded-md"
		when /^(search_.+)$/
			item[:content] = SearchBoxComponent.new(item)
		when "gap", "label", "lines", "side_cell", "string", "subtitle", "title", "top_cell"
			set_text_item(item)
		when "partial"
			item[:content] = PartialComponent.new(partial: item[:partial], locals: item[:locals] || {})
		when /^(select_.+|.+box|.+_area)$/
			item[:class] ||= "align-top"
		when "separator"
			item[:stroke] ||= "solid"
		when "steps"
			item[:content] = StepsComponent.new(steps: item[:steps], court: item[:court])
		when "symbol"
			hashify_symbol(item)
			item[:content] = SymbolComponent.new(item[:symbol][:concept], **item[:symbol][:options])
		else
			item[:i_class] = "rounded p-0" unless item[:kind] == :gap
		end
		grid_item_css(item)
		item
	end

	# parse all specified items to set the correct rendering
	def parse_rows(rows)
		res  = Array.new
		@cols = 1
		rows.map do |row|
			res << [] # new row n header
			rcols = 0
			row.map do |item|
				@cols = 1
				item  = parse_item(item)
				rcols += 1
				res.last << item
			end
			@cols = rcols if rcols > @cols
		end
		res
	end

	# wrapper to render a specific item
	def render_item(item)
		grid_item_tag(item) do
			case item[:kind].to_s
			when /^(accordion|button|contact|diagram.*|dropdown|search_.+|partial|steps|svg|symbol)$/
				render item[:content]
			when /^(select_.+|.+box|.+_area|hidden|radio.+|upload)$/
				render InputBoxComponent.new(item, form: @form)
			when "gap"
				("&nbsp;" * item[:size]).html_safe
			when /^(.*icon.*|image)$/
				render_image_item(item)
			when "lines"
				item[:value].map { |line| "&nbsp;#{line}<br>" }.join.html_safe
			when "nested_form"
				render NestedComponent.new(model: item[:model], key: item[:key], form: @form, child: item[:child], row: item[:row], filter: item[:filter])
			when "roles"
				item[:symbols].each { |symbol| concat(render_image(symbol)) }
			when "separator"
				("<hr class=\"#{item[:stroke]}\"").html_safe
			when "table"
				render TableComponent.new(item[:value], controller: item[:controller], align: item[:align], form: @form)
			when "targets"
				render_targets_item(item)
			else
				if item[:dclass]
					concat((item[:value].tap { |value| break "<div class=\"#{item[:dclass]}\">#{value}</div>" }.html_safe))
				else
					concat(item[:value])
				end
			end
		end
	end

	# render an image item
	def render_image_item(item)
		html = ""
		if item[:label]
			html += "<div class=\"inline-flex items-center\">"
			html += "#{item[:label]}&nbsp;" if item[:right]
		end
		html += render_image(item)
		if item[:label]
			html += "&nbsp;#{item[:label]}" unless item[:right]
			html += "</div>"
		end
		html.html_safe
	end

	# Add this private method to GridComponent
	def render_targets_item(item)
		html = ""
		last = item[:targets]&.last
		item[:targets]&.each do |target|
			html += "<div class=\"inline-flex items-center space-x-2 py-1\">"
			html += render(TrafficLightComponent.new(status: target[:status])) unless @form
			html += "<span>#{target[:text]}</span>"
			html += render(InputBoxComponent.new({ kind: :number_box, max: 100, step: 1, value: target[:completion] })) if @form
			html += "</div>"
			html += "<br>" unless target == last
		end
		html.html_safe
	end

	# used for all icon/image items - except for :image_box
	def set_image(item)
		case item[:kind]
		when :header_icon
			item[:size]  ||= "50x50"
			item[:align]   = "center"
			item[:class] ||= "align-top"
			item[:css]   ||= "max-w-75 max-h-100 rounded align-top m-1"
			item[:rows]    = 2 unless item[:rows]
		when :icon, :icon_label
			item[:size]  ||= "25x25"
			if item[:label] && item[:kind] == :icon
				item[:class] ||= "align-top inline-flex"
			else
				item[:align] ||= "right"
			end
		when :image
			item[:css] ||= "rounded align-top m-1"
		end
		if item[:symbol].present?	# symbol definition
			hashify_symbol(item)	# ensure it is a hash
			item[:symbol][:options][:css]  ||= item[:css]
			item[:symbol][:options][:size] ||= item[:size]
			item[:value] = SymbolComponent.new(item[:symbol][:concept], **item[:symbol][:options])
		else
			item[:i_class] ||= item[:css]
		end
	end

	# used for all text-like items - except for inputboxes, of course
	def set_text_item(item)
		case item[:kind]
		when :gap
			item[:size]  ||= 4
		when :label
			l_cls          = "inline-flex font-semibold"
			item[:class]   = item[:class] ? "#{item[:class]} #{l_cls}" : l_cls
		when :lines
			item[:class] ||= "align-top border px py"
		when :side_cell
			item[:align] ||= "right"
			item[:class]   = "align-center font-semibold text-indigo-900"
		when :string
			item[:class] ||= "align-top"
		when :subtitle
			item[:class]   = "align-top font-bold"
		when :title
			item[:class]   = "align-top font-bold text-yellow-600"
		when :top_cell
			item[:class]   = "font-semibold bg-indigo-900 text-gray-300 align-center border px py"
		end
	end
end
