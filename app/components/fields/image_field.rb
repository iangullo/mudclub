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
#
# ImageField class for FieldsComponents
# conceived to serve as abstraction layer for all images/icons.
# recognised kinds are: "header-icon", "icon" and "icon-label", "image"
class ImageField < BaseField
	include ActionView::Helpers::TagHelper
	include ActionView::Helpers::AssetTagHelper

	def initialize(field)
		super(field)
		set_attributes
		set_tooltip if field[:tip]
		@image = set_image
	end

	def content
		if self.kind == "icon-label"
			if @fdata[:right]
				content = "#{@fdata[:label]}&nbsp;#{@image}"
			else
				content = "#{@image}&nbsp;#{@fdata[:label]}"
			end
			content_tag(:span, content.html_safe, class: @fdata[:class])
		else
			if @fdata[:tip]
				tag(:div) do
					tag(:button, type: 'button', 'data-tooltip-target': @fdata[:tip_id], 'data-tooltip-placement': 'bottom') do
						@image
					end
					tag(:div, id: "tooltip-#{@fdata[:tip_id]}", role: "tooltup", class: @fdata[:tip_cls]) do
						@fdata[:tip]
					end
				end
			else
				@image
			end
		end
	end

	private
		def set_attributes
			case self.kind
			when "header-icon"	# header icons are different
				@fdata[:size] ||= "50x50"
				@fdata[:rows] ||= 2
				@fdata[:align]  = "center"
				@fdata[:class]  = [@fdata[:class], :align_top].compact.join(" ")
			when "icon", "icon-label"
				@fdata[:size] ||= "25x25"
				if @fdata[:label]
					@fdata[:class] ||= "align-top inline-flex"
				else
					@fdata[:align] ||= "right"
					@fdata[:class]   = [@fdata[:class], :align_middle].compact.join(" ")
				end
			when "image"
				@fdata[:class] = [@fdata[:class], :align_middle].compact.join(" ")
			end
		end

		def set_tooltip
			@fdata[:tip_id]  = SecureRandom.hex(5)
			@fdata[:tip_cls] = "absolute z-10 invisible inline-block px py text-sm font-medium text-gray-100 bg-gray-700 rounded-lg shadow-sm opacity-0 tooltip"
		end

		def set_image
			img = (self.kind == "icon-label" ? @fdata[:icon] : @fdata[:value])
			img = "/assets/#{img}" unless img.start_with?("/assets/") || img.start_with?("data:")
			if self.kind == "icon-label"
				image_tag(img, size: @fdata[:size])
			else
				image_tag(img, size: @fdata[:size], class: @fdata[:class])
			end
		end
end