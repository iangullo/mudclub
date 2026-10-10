# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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

# InputBoxComponent - ViewComponent to manage standardised form input boxes.
# managing different kinds of input box:
# => :date_box - :key (field name), :value (date_field), :s_year (start_year)
# => :email_box - :key (field name), :value (email_field), :size (box size)
# => :hidden - :key (field name), :value (number_field)
# => :image_box - :key (attribute of image), :value (path to image), :size (optional)
# => :number_box - :key (field name), :value (number_field), size:
# => :label_checkbox - :key (attribute of checkbox), :value (added text)
# => :number_box -  :key (field name), :value (number_field), size:
# => :password_box - :key (field name), :value (password_field)
# => :radio_button - :key (field name), :value (field value)
# => :radio_group - :key (field name), :value (selected value), :options (array of {value:, label:, hint:} options)
# => :rich_text_area - :key (field name)
# => :text_area - :key (field name), :value (text_field), :size (box size), lines: number of lines
# => :text_box - :key (field name), :value (text_field), :size (box size), :options (optional array of autocomplete options)
# => :time_box - :hour & :min (field names)
# => :select_box - :key (field name), :options (array of valid options), :value (form, select)
# => :select_checkboxes - :key (field name), :collection, :value (form, select)
# => :select_collection - :key (field name), :collection, :value (form, select)
# => :select_load - :key (field name), :icon, :label, :value (form, select)
# => :upload - Upload file input - hidden and linked to an 'upload' ButtonComponent
class InputBoxComponent < ApplicationComponent
	DEF_INPUT_CLASS = "rounded py-0 px-1 shadow-inner border-gray-200 bg-gray-50 focus:ring-blue-700".split(" ")
	DEFAULT_BOX_SIZE = { image_box: "50x50", number_box: 5, time_box: 5, default: 20 }
	attr_writer :form, :session

	def initialize(field, form: nil, session: nil)
		@i_class = DEF_INPUT_CLASS.dup
		@form    = form	# set form, if passed
		@session = session
		@fdata   = field
		sanitize_image! if @fdata[:kind] == :image_box
		@fdata[:align] ||= "left"
		@fdata[:class] ||= "align-top"
		@fdata[:fname]   = @fdata[:value].to_s.presence || I18n.t("status.no_file") if @fdata[:kind] == :upload
		set_box_size
		set_box_attributes
		set_box_data
		@i_class = @i_class.join(" ")
	end

	private
		# handle mandatory conditions to bind with stimulus controller
		def generate_condition(mandatory, kind: :text)
			conditions = []

			if mandatory.is_a?(Hash)
				case kind
				when :date
					conditions << "date_min:#{mandatory[:min]}" if mandatory[:min]
					conditions << "date_max:#{mandatory[:max]}" if mandatory[:max]
				else
					conditions << "length:#{mandatory[:length]}" if mandatory[:length]
					conditions << "min:#{mandatory[:min]}"       if mandatory[:min]
					conditions << "max:#{mandatory[:max]}"       if mandatory[:max]
				end
			end

			conditions << "presence" if conditions.empty? && mandatory

			result = {
				condition: conditions.join(";"),
				identifier: unique_identifier("inputbox")
			}

			unless_ = mandatory[:unless] if mandatory.is_a?(Hash)
			if unless_.present?
				result[:mandatory_unless] = Array(unless_)
					.map { |name| "[data-optional-name='#{name}']:not(.hidden)" }
					.join(", ")
			end

			result
		end

		# offload some initial setting of field data
		def set_box_attributes
			kind_mappings = {
				image_box: { class: "group flex relative overflow-hidden justify-center align-middle rounded border-gray-300 border-1" },
				number_box: { class: "text-black text-right", min: @fdata[:min] || 0, max: @fdata[:max] || 99, step: @fdata[:step] },
				label_checkbox: { class: "align-middle m-1 rounded bg-gray-200 text-blue-700" },
				radio_button: { class: "m-1" },
				radio_group: { class: "m-1" },
				rich_text_area: { class: "trix-content" },
				text_box: { class: "overflow-hidden overflow-ellipsis" },
				time_box: { class: "text-right" },
				upload: { class: "align-middle px py", i_class: "inline-flex items-center rounded-md shadow bg-gray-100 ring-2 ring-gray-300 hover:bg-gray-300 focus:border-gray-300 font-semibold text-sm px-1 py m-1 justify-center" }
			}

			mapping = kind_mappings[@fdata[:kind]]
			return unless mapping
			@i_class << (mapping[:i_class] || mapping[:class])
			@fdata.merge!(mapping.reject { |key, _| key == :class })
		end

		# data atributes to pass on to controllers/forms
		def set_box_data
			@i_data = @fdata[:i_data].is_a?(Hash) ? @fdata[:i_data] :  {}

			case @fdata[:kind]
			when :hidden
				return
			when :image_box
				@i_data.merge!({ action: "change->imagebox#handleFileChange", imagebox_target: "imageFile" })
				@width  = ensure_px((@fdata[:width] || 75).to_s)
				@height = ensure_px((@fdata[:height] || 100).to_s)
				@fdata[:class] += " w-full"
			when :text_box
				if @fdata[:options].is_a?(Hash)
					@i_data.merge!({ "data-optvalues" => @fdata[:options].values })
				end
			when :upload
				@fdata[:css] = "max-h-6 min-h-4 h-5 m-1" if @fdata[:icon] || @fdata[:symbol]
				@i_data.merge!({ upload_target: "fileInput", action: "change->upload#displayName" })
			else
			end

			if @fdata[:mandatory].present?
				existing = @i_data[:action].to_s
				merged   = [ existing, "mandatory#check" ].reject(&:blank?).join(" ")
				@i_data.merge!({ mandatory_input: true, action: merged })
				@i_data.merge!(generate_condition(@fdata[:mandatory]))
			end
		end

		# calculate size of box
		def set_box_size
			unless @fdata[:size]
				case @fdata[:kind]
				when :image_box
					@fdata[:size] = DEFAULT_BOX_SIZE[:image_box]
					dimensions = @fdata[:size].split("x")
					@width = ensure_px(dimensions[0])
					@height = ensure_px(dimensions[1])
				when :number_box, :time_box
					box_size = DEFAULT_BOX_SIZE[@fdata[:kind]]
				else
					if @fdata[:options].present?
						optnames = @fdata[:options].is_a?(Hash) ? @fdata[:options].keys : @fdata[:options]
						longest  = optnames.map(&:to_s).max_by(&:length).length
						box_size = [ longest, 10 ].max
					else
						box_size ||= DEFAULT_BOX_SIZE[:default]
					end
				end
				@fdata[:size] ||= box_size - 3
			end
		end

		def ensure_px(val)
			val.ends_with?("px") ? val : "#{val}px"
		end

		def sanitize_image!
			return if valid_attachment?(@fdata[:value])
			@fdata[:value] = nil
		end

		def valid_attachment?(attachment)
			return false unless attachment.respond_to?(:attached?)
			return false unless attachment.attached?

			attachment.blob.present?

			true
		rescue ActiveStorage::FileNotFoundError,
					ActiveStorage::IntegrityError,
					ActiveRecord::RecordNotFound
			false
		end
end
