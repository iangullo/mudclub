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

# FieldItemComponent - ViewComponent to produce items within a FieldsComponent
#		kinds of content for each FieldItem:
# => :accordion: a collapsible accordion element
# => :button: a specific ButtonComponent - passed as argument item[:button]
# => :contact: mailto:, tel: and whatsapp: buttons for a person
# => :date_box: :key (item name), :value (date_field), :s_year (start_year)
# => :dropdown: a DropdownComponent - passed as argument to the menu generator
# => :diagram: svgdata (diagram SVG data we are editing), :court (symbol for court background image)
# => :email_box: :key (item name), :value (email_field), :size (box size)
# => :gap: :size (count of &nbsp; to separate content)
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
# => :optional_section: handle auto hide/unhide of optional form fields
# => :partial: :partial (html.erb partial templateo), :locals (hash of local variables)
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
class FieldItemComponent < ApplicationComponent
	# Keep these ranges in sync with the @source inline() calls in
	# app/assets/tailwind/application.css
	WIDE_KINDS     = %i[accordion diagram table rich_text_area steps svg].freeze
	COL_SPAN_RANGE = (1..12).freeze
	ROW_SPAN_RANGE = (1..6).freeze

	def initialize(item, form: nil)
		@item = parse_field(item)
		@form  = form
	end

	def call
		# field_item_tag do
		tablecell_tag(@item) do
			render_field_content
		end
	end

	def form=(formobj)
		@form = formobj
		@item[:content].form = formobj if @item[:content]&.respond_to?(:form=)
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

		def field_css(item)
			d_class  = item[:class].to_s.split(" ")
			d_class << "w-full" if WIDE_KINDS.include?(item[:kind])
			d_class << field_align(item[:align]) if item[:align].present?
			d_class << span_class("col", item[:cols], COL_SPAN_RANGE) if item[:cols].present?
			d_class << span_class("row", item[:rows], ROW_SPAN_RANGE) if item[:rows].present? && item[:kind] != :table
			item[:class] = d_class.compact.join(" ") if d_class.present?
		end

		def field_item_tag(&block)
			content_tag(:div, class: @item[:class], data: @item[:data], &block)
		end

		def parse_field(item)
			case item[:kind].to_s	# need to adapt to each fields "kind"
			when "accordion"
				item[:content] = AccordionComponent.new(title: item[:title], tail: item[:tail], mode: item[:mode] || :scroll, objects: item[:objects])
			when "button"	# item[:button] has to contain the button definition
				item[:content] = ButtonComponent.new(**item[:button])
			when "contact"
				item[:content] = ContactComponent.new(website: item[:website], email: item[:email], phone: item[:phone], device: item[:device])
			when "diagram"
				item[:content] = DiagramComponent.new(court: item[:court], svgdata: item[:svgdata], css: item[:css])
			when "dropdown"	# item[:button] has to contain the button definition
				item[:content] = DropdownComponent.new(item[:button])
			when /^(.*icon.*|image)$/
				set_image(item)
			when "label_checkbox"
				item[:class] ||= " align-middle rounded-md"
			when "optional_section"
				item[:content] = FieldsComponent.new(item[:fields])
			when /^(search_.+)$/
				item[:content] = SearchBoxComponent.new(item)
			when "gap", "label", "lines", "side_cell", "string", "subtitle", "title", "top_cell"
				set_text_field(item)
			when "partial"
				item[:content] = PartialComponent.new(partial: item[:partial], locals: item[:locals] || {})
			when /^(select_.+|.+box|.+_area)$/
				item[:class] ||= "align-top"
			when "separator"
				item[:stroke] ||= "solid"
			when "steps"
				item[:content] = StepsComponent.new(steps: item[:steps], court: item[:court], max_height: item[:max_height])
			when "symbol"
				hashify_symbol(item)
				item[:content] = SymbolComponent.new(item[:symbol][:concept], **item[:symbol][:options])
			when "table"
				item[:value] ||= item.slice(:title, :rows, :form, :align)
			else
				item[:i_class] = "rounded p-0" unless item[:kind] == :gap
			end
			item[:align] ||= "left"
			field_css(item)
			item
		end

		def render_field_content
			case @item[:kind].to_s
			when /^(accordion|button|contact|diagram.*|dropdown|search_.+|partial|steps|symbol)$/
				render @item[:content]
			when /^(select_.+|.+box|.+_area|hidden|radio.+|upload)$/
				render InputBoxComponent.new(@item, form: @form)
			when "gap"
				("&nbsp;" * @item[:size]).html_safe
			when /^(.*icon.*|image)$/
				render_image_field
			when "lines"
				@item[:value].map { |line| "&nbsp;#{line}<br>" }.join.html_safe
			when "nested_form"
				render NestedComponent.new(model: @item[:model], key: @item[:key], form: @form, child: @item[:child], row: @item[:row], filter: @item[:filter])
			when "optional_section"
				render_optional_section
			when "pdf"
				render PdfComponent.new(file: @item[:value], height: @item[:height], width: @item[:width], zoom: @item[:zoom], css:    @item[:css])
			when "roles"
				@item[:symbols].each { |symbol| concat(render_image(symbol)) }
			when "separator"
				("<hr class=\"border-#{@item[:stroke]}\"").html_safe
			when "table"
				render TableComponent.new(@item[:value], align: @item[:align], form: @form)
			when "targets"
				render_targets_field
			else
				if @item[:dclass]
					concat((@item[:value].tap { |value| break "<div class=\"#{@item[:dclass]}\">#{value}</div>" }.html_safe))
				else
					concat(@item[:value])
				end
			end
		end

		# render an image item
		def render_image_field
			html = ""
			if @item[:label]
				html += "<div class=\"inline-flex items-center\">"
				html += "#{@item[:label]}&nbsp;" if @item[:right]
			end
			html += render_image(@item)
			if @item[:label]
				html += "&nbsp;#{@item[:label]}" unless @item[:right]
				html += "</div>"
			end
			html.html_safe
		end

		def render_optional_section
			wrapper_class = [ @item[:class], (@item[:hidden_start] ? "hidden" : nil) ].compact.join(" ")
			wrapper_attrs = {
				"optional-fields-target": "section",
				"optional-name":          @item[:name]
			}

			content_tag(:div, class: wrapper_class.presence, data: wrapper_attrs) do
				render @item[:content]
			end
		end

		# Add this private method to FieldsComponent
		def render_targets_field
			html = ""
			last = @item[:targets]&.last
			@item[:targets]&.each do |target|
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
				item[:content] = SymbolComponent.new(item[:symbol][:concept], **item[:symbol][:options])
			else
				item[:i_class] ||= item[:css]
			end
		end

		# used for all text-like fields - except for inputboxes, of course
		def set_text_field(item)
			case item[:kind]
			when :gap
				item[:size]  ||= 4
			when :label
				l_cls          = "inline-flex font-semibold"
				item[:class]   = item[:class] ? "#{item[:class]} #{l_cls}" : l_cls
			when :lines
				item[:class] ||= "align-top border px-2 py-1"
			when :side_cell
				item[:align] ||= "right"
				item[:class]   = "font-semibold text-indigo-900"
			when :string
				# item[:class] ||= "align-center"
				# item[:align] ||= "center"
			when :subtitle
				item[:class]   = "font-bold"
			when :title
				item[:class]   = "font-bold text-yellow-600"
			when :top_cell
				item[:class]   = "font-semibold bg-indigo-900 text-gray-300 border px-2 py-1"
				item[:align] ||= "center"
			end
		end

		# Builds an "md:col-span-N" / "md:row-span-N" class, clamped to `range`
		# so it always matches a class in the compiled Tailwind CSS.
		def span_class(axis, value, range)
			requested = value.to_i
			clamped   = requested.clamp(range.first, range.last)

			if requested != clamped && Rails.env.development?
				Rails.logger.warn(
					"[FieldItemComponent] md:#{axis}-span-#{requested} " \
					"clamped to #{clamped} (range: #{range.first}–#{range.last})"
				)
			end

			"md:#{axis}-span-#{clamped}"
		end
end
