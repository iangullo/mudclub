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
	def initialize(namespace: "common", type: :icon, concept:, variant: "default", css: nil, label: nil, size: nil, view_box: nil)
		@symbol   = SymbolRegistry.fetch(namespace:, type:, concept:, variant:)
		@css      = css
		@label    = label
		@view_box = view_box || @symbol["viewBox"] || "0 0 128 128"
		if size.present?
			@width  = size.split("x")[0]
			@height = size.split("x")[1]
		end
	end

	def call
		return unless @symbol
		content_tag(
			:svg,
			raw(@symbol.children.to_xml),
			viewBox: @view_box,
			xmlns: 'http://www.w3.org/2000/svg',
			preserveAspectRatio: 'xMidYMid meet',
			class: @css,
			width: @width,
			height: @height,
			aria: { label: @label }
		)
	end
end
