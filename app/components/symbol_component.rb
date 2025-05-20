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
	attr_reader :namespace, :type, :concept, :variant

	# options mudsplat expects: namespace:, type:, variant:, css:, label:, size:, view_box:, data: {}
	def initialize(concept, **options)
		@concept    = concept.to_s
		parse_options(options)
		@symbol     = SymbolRegistry.fetch(namespace:, type:, concept:, variant:)
		@view_box ||= @symbol&.[]("viewBox") || "0 0 128 128"
	end

	def call
		return missing_svg unless @symbol
		content_tag(
			:svg,
			raw(@symbol.children.to_xml),
			viewBox: @view_box,
			xmlns: 'http://www.w3.org/2000/svg',
			preserveAspectRatio: 'xMidYMid meet',
			class: @css,
			width: @width,
			height: @height,
			aria: { label: @label },
			role: "img",
			data: @data
		)
	end

	private

	# set internal Symbol paremeters
	def parse_options(options)
		@namespace = options[:namespace]&.to_s || "common"
		@type      = options[:type]&.to_sym || :icon
		@variant   = options[:variant]&.to_s || "default"
		@css       = options[:css].presence || default_class(@type)
		@view_box  = options[:view_box].presence
		@label     = options[:label].presence
		@data      = {	# data-* for Stimulus + extra options
			namespace: @namespace,
			type: @type,
			concept: @concept,
			variant: @variant
		}.merge(options[:data] || {})
		@width, @height = parse_size(options[:size])
	end

	def parse_size(size)
		case size
		when /^\d+x\d+$/ then size.split("x").map(&:to_i)
		when /^\d+$/     then [size.to_i, size.to_i]
		else [25, 25]
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
end
