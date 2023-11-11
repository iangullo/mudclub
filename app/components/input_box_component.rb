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

# InputBoxComponent - ViewComponent to manage standardised form input boxes.
# managing different kinds of input box:
# => "date-box": :key (field name), :value (date_field), :s_year (start_year)
# => "email-box": :key (field name), :value (email_field), :size (box size)
# => "hidden": :key (field name), :value (number_field)
# => "image-box": :key (attribute of image), :value (path to image), :size (optional)
# => "number-box": :key (field name), :value (number_field), size:
# => "label-checkbox": :key (attribute of checkbox), :value (added text)
# => "number-box": :key (field name), :value (number_field), size:
# => "password-box": :key (field name), :value (password_field)
# => "rich-text-area": :key (field name)
# => "text-area": :key (field name), :value (text_field), :size (box size), lines: number of lines
# => "text-box": :key (field name), :value (text_field), :size (box size)
# => "time-box": :hour & :min (field names)
# => "select-box": :key (field name), :options (array of valid options), :value (form, select)
# => "select-checkboxes": :key (field name), :collection, :value (form, select)
# => "select-collection": :key (field name), :collection, :value (form, select)
# => "select-load": :key (field name), :icon, :label, :value (form, select)

class InputBoxComponent < ApplicationComponent
	DEF_INPUT_CLASS = "rounded py-0 px-1 shadow-inner border-gray-200 bg-gray-50 focus:ring-blue-700 focus:border-blue-700".split(" ")
	attr_writer :form, :session

	def initialize(field:, form: nil, session: nil)
		@i_class = DEF_INPUT_CLASS.dup
		@form    = form	# set form, if passed
		@session = session
		@fdata   = field
		@fdata[:align] ||= "left"
		@fdata[:class] ||= "align-top"
		set_box_size
		set_box_attributes
		@i_class  = @i_class.join(" ")
	end

	private
		# offload some initial setting of field data
		def set_box_attributes
			kind_mappings = {
				"image-box" => { class: "group flex relative w-75 h-100 overflow-hidden justify-center align-middle rounded border-gray-300 border-1" },
				"number-box" => { class: "text-black text-right", min: @fdata[:min] || 0, max: @fdata[:max] || 99, step: @fdata[:step] || 1 },
				"label-checkbox" => { class: "align-middle m-1 rounded bg-gray-200 text-blue-700" },
				"rich-text-area" => { class: "trix-content" },
				"text-area" => {class: "text-md"},
				"time-box" => { class: "text-right" },
				"upload" => { class: "align-middle px py", i_class: "inline-flex align-center rounded-md shadow bg-gray-100 ring-2 ring-gray-300 hover:bg-gray-300 focus:border-gray-300 font-semibold text-sm whitespace-nowrap px-1 py-1 m-1 max-h-6 max-w-6 align-center" }
			}

			mapping = kind_mappings[@fdata[:kind]]
			return unless mapping

			@i_class << (mapping[:i_class] ? mapping[:i_class] : mapping[:class])
			@fdata.merge!(mapping.reject { |key, _| key == :class })
		end

		# calculate size of box
		def set_box_size
			unless @fdata[:size]
				case @fdata[:kind]
				when "image-box"
					@fdata[:size] = "50x50"
				when "time-box", "number-box"
					box_size = 5
				else
					if @fdata[:options].present?
						box_size = 10
						longest  = @fdata[:options].map(&:to_s).max_by(&:length).length
						box_size = longest if longest > box_size
					else
						box_size = 20
					end
				end
				@fdata[:size] ||= box_size - 3
			end
		end
end
