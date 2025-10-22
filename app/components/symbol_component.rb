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

# Manage SVG Symbols for views & buttons
class SymbolComponent < ApplicationComponent
	# Initialize with a concept and various options.
	# Options expected (mud-splat style): namespace:, type:, variant:, css:, label:, size:, view_box:, data: {}
	def initialize(concept, **options)
		@concept = concept.to_s
		parse_options(options)
		@symbol = SymbolRegistry.fetch(
			namespace: @namespace,
			type: @type,
			concept: @concept,
			variant: @variant
		)
		@view_box ||= @symbol&.[]("viewBox") || "0 0 128 128"
	end

	def call
		return missing_svg unless @symbol

		apply_customizations

		content  = []
		content << content_tag(:title, h(@title)) if @title
		content << wrapped_symbol_content

		svg_attrs = {
			id: @data[:id],
			class: @css,
			data: @data,
			aria: (@data[:label].present? ? { label: @data[:label] } : nil),
			role: "img",
			viewBox: @view_box,
			preserveAspectRatio: "xMidYMid meet"
		}

		unless @group
			svg_attrs.merge!({ width: @width, height: @height, xmlns: "http://www.w3.org/2000/svg" })
		end

		tag_name = @group ? :g : :svg
		content_tag(tag_name, safe_join(content), svg_attrs)
	end

	def full_id
		"#{@namespace}.#{@type}.#{@concept}.#{@variant}"
	end

	def to_img
		svg_markup = call.to_s.strip
		encoded = Base64.strict_encode64(svg_markup)
		"data:image/svg+xml;base64,#{encoded}"
	end

	# accessor to read the symbol_viewbox in "standard" SVG format
	def view_box
		vb_attrs = @view_box.presence&.split(" ")
		{
			x: vb_attrs[0].presence || 0,
			y: vb_attrs[1].presence || 0,
			width: vb_attrs[2].presence || @width,
			height: vb_attrs[3].presence || @height
		}
	end

	private

	# Apply visual customizations on the @symbol object itself.
	# If the symbol contains a <tspan> with id starting 'label', replace its content with @label and update text color if provided.
	# If no such element exists, the label will only be reflected in the aria-label attribute for accessibility.
	# Also updates fill and stroke colors on all elements unless explicitly set to 'none'.
	def apply_customizations
		apply_label if @data[:label].present?
	end

	def apply_label
		@symbol.css("tspan[id^='label']").each do |el|
			el.content = @data[:label].to_s
			el["fill"] = @data[:text_color] if @data[:text_color]
		end
	end

	def default_class(type)
		case type
		when :icon then "m-1"
		when :object then "inline-block"
		when :court then "w-full h-auto"
		else "inline-block"
		end
	end

	def missing_svg
		content_tag(:svg, "", class: "invisible", "data-debug": "missing-symbol")
	end

	# Parse and set internal symbol parameters from options hash and data
	def parse_options(options)
		@css      = safe_attr(options, :css) || default_class(@type)
		@data     = safe_attr(options, :data) || {}
		@group    = safe_attr(options, :group) || false
		@title    = safe_attr(options, :title) || @data[:title].presence
		@view_box = safe_attr(options, [ :view_box, :viewBox ]) || safe_attr(@data, [ :view_box, :viewBox ])
		@wrap     = safe_attr(options, :wrap) || false

		parse_symbol_id(options)

		@width, @height = parse_size(options[:size])

		@data[:kind]      ||= @type
		@data[:symbol_id] ||= [ @namespace, @type, @concept, @variant ].join(".")

		%i[id, fill label text_color transform stroke].each do |key|
			@data[key] ||= safe_attr(options, key) || safe_attr(@data, key)
		end
	end

	def parse_symbol_id(options)
		symbol_id = safe_attr(@data, [ :symbol_id, :symbolId ]) || safe_attr(options, [ :symbol_id, :symbolId ])
		if symbol_id.present? && symbol_id.count(".") == 3
			@namespace, type_str, @concept, @variant = symbol_id.split(".")
			@type = type_str.to_sym
		else
			@namespace = options[:namespace] || "common"
			@type      = options[:type] || :icon
			@variant   = options[:variant] || "default"
		end
	end

	def parse_size(size)
		case size
		when /^\d+x\d+$/ then size.split("x").map(&:to_i)
		when /^\d+$/ then [ size.to_i, size.to_i ]
		else [ 25, 25 ]
		end
	rescue
		[ 25, 25 ]
	end

	def wrapped_symbol_content
		group_attrs = @data[:transform] || @data[:x] ? { draggable: true, kind: "symbol", transform: @data[:transform], position: @data[:position] } : {}
		if @wrap || group_attrs.present?
			content_tag(:g, raw(@symbol.children.to_xml), group_attrs)
		else
			raw(@symbol.children.to_xml)
		end
	end
end
