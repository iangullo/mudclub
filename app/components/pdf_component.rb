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

# PdfComponent - ViewComponent to render PDF files as FieldComponents
class PdfComponent < ApplicationComponent
	def initialize(file:, height: nil, width: nil, zoom: false, css: nil)
		@file   = file
		@height = height
		@width  = width
		@zoom   = zoom
		@css    = css
	end

	def call
		content_tag(:div, class: @css.presence || "w-full") do
			tag.iframe(
				src: helpers.url_for(@file),
				class: iframe_classes,
				style: iframe_style.presence,
				loading: "lazy"
			)
		end
	end

	def render?
		@file.present?
	end

	private
		def iframe_classes
			classes = [ "border", "rounded" ]
			classes << "h-full" unless @height.present?
			classes << "w-full" unless @width.present?
			classes.join(" ")
		end

		def iframe_style
			styles = []
			styles << "height: #{@height}" if @height.present?
			styles << "width: #{@width}"   if @width.present?
			styles.join("; ")
		end
end
