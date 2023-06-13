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
# InputBoxField class for FieldsComponents
# conceived to serve as abstraction layer for all text-boxes
# @kinds: date-box, email-box, label-checkbox, number-box, password-box,
#         rich-text-area, select-checkboxes, select-collection, select-box,
#	        text-area, select-load, text-box, time-box
class InputBoxField < BaseField
	INPUT_CLASS = "rounded py-0 px-1 shadow-inner border-gray-200 bg-gray-50 focus:ring-blue-700 focus:border-blue-700".freeze

	def initialize(field, form=nil,session=nil)
		super(field, form, session)
		@i_class         = [INPUT_CLASS]
		@fdata[:class] ||= "align-top"
		set_box_attributes
		set_box_size
		@fdata[:i_class] = @i_class.join(" ")
	end

	# attempt to render content
	def content
		case @fdata[:kind]
		when "date-box"
			@form.date_field(self.key, value: self.value, start_year: self.s_year, end_year: (self.e_year ? self.e_year : Time.now.year), class: self.i_class)
		when "email-box"
			@form.email_field self.key, placeholder: self.placeholder, size: self.size, class: self.i_class
		when "hidden"
			@form.hidden_field(self.key.to_sym, value: self.value)
		when "label-checkbox"
			# not so simple?
		when "number-box"
			html  = @form.number_field self.key, value: self.value, size: self.size ? self.size: 2, min: self.min, max: self.max, step: self.step, class: self.i_class
			html += self.units.to_s
		when "password-box"
			@form.password_field self.key, placeholder: self.placeholder, class: self.i_class, size: self.size
		when "rich-text-area"
			@form.rich_text_area self.key, class: self.i_class
		when "select-box"
			@form.select self.key, self.options, {selected: self.value ? self.value : self.options.first}, class: self.i_class
		when "select-checkboxes"
			@form.collection_check_boxes self.key, self.options, :id, :to_s do |obj|
				obj.check_box({class: 'rounded bg-gray-200 text-blue-700'}) + " " + obj.object.to_s
			end
		when "text-area"
			@form.text_area self.key, value: self.value, cols: self.size, rows: self.lines, class: self.i_class
		end
	end

	# accessors for specific data
	def s_year
		@fdata[:s_year]
	end

	def e_year
		@fdata[:e_year]
	end

	def placeholder
		@fdata[:placeholder]
	end

	def hour
		@fdata[:hour]
	end

	def min
		@fdata[:min]
	end

	def max
		@fdata[:max]
	end

	def units
		@fdata[:units]
	end

	def step
		@fdata[:step]
	end

	def lines
		@fdata[:lines]
	end

	def options
		@fdata[:options]
	end

	def hidden
		@fdata[:hidden]
	end

	def url
		@fdata[:url]
	end

	def right
		@fdata[:right]
	end

	private
		# methods to offload some initial setting of field data
		# to improve readability
		def set_box_attributes
			case @kind
			when "rich-text-area"
				@i_class << "trix-content"
			when "number-box", "time-box"
				@i_class << "text-right"
				@fdata[:min]  ||= 0
				@fdata[:max]  ||= 99
				@fdata[:step] ||= 1
			when "label-checkbox"
				l_cls = "inline-flex align-top font-semibold"
				@fdata[:class] = @fdata[:class] ? @fdata[:class] + " #{l_cls}" : l_cls
				@i_class = ["rounded", "bg-gray-200", "text-blue-700"]
			end
		end

		# calculate size of box
		def set_box_size
			unless @fdata[:size]
				case @fdata[kind]
				when "time-box", "number-box"
					box_size = 5
				else
					if @fdata[:options].present?
						box_size = 10
						options  = @fdata[:options]
						longest  = options.map(&:to_s).max_by(&:length).length
						box_size = longest if longest > box_size
					else
						box_size = 20
					end
				end
				@fdata[:size] = box_size - 3
			end
		end
end
