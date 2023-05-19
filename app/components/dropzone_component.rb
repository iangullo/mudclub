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

# DropzoneComponent - ViewComponent to render reusable boxes showing either a dropzone (or image, if attached)
# for any object with a "has_attached" image field.
# => :object => object with the attached image
# => :key => name of attached image field
# => :_class => class to apply to div
# => :size => size to scale the attachment
# => :form => the form to which this field is to respond (optional)
class DropzoneComponent < ApplicationComponent
	# create the component
	def initialize(object:, key:, options: nil)
		@object = object
		@key    = key.to_sym
		@class  = options[:class] ? options[:class] : "max-h-96 max-w-96"
		@size   = options[:size] ? options[:size] : "96x96"
		@multi  = options[:multi] ? options[:multi] : false
	end

	def call
		if @object.send(@key).attached?
			render_attachment
		else
			render_input
		end
	end

	private
		# called when @object has an attached @image
		def render_attachment
			tag.div(class: 'preview') {
				concat(render_image)
				concat(render_delbutton)
			}
		end

		# renders the @image, called when atached
		def render_image
			binding.break
			image_url = @object.send(@key).url
			tag.img src: image_url, class: @class, size: @size
		end

		# delete button to clear atached images
		def render_delbutton
			tag.button(class: 'delete-button', data: { target: 'dropzone.deleteButton' }) do
				tag.img(src: asset_path('delete.svg'), class: 'delete-icon', alt: I18n.t('question.delete'), size: '25x25')
			end
		end

		# pure dropzone when no attachment exists
		def render_input
			dropzone_controller_div do
				tag.input type: 'file', multiple: @multi, data: { target: 'dropzone.input' }
			end
		end
		# dropzone div for image uploads
		def dropzone_controller_div
			data = {
				controller: "dropzone",
				'dropzone-max-file-size'=>"1",	# 1MB max
				'dropzone-max-files' => "1",	# only one file
				'dropzone-accepted-files' => 'image/jpeg,image/jpg,image/png,image/gif,image/svg',
				'dropzone-dict-file-too-big' => "Too large! (should be < {{maxFilesize}} MB)",
				'dropzone-dict-invalid-file-type' => "Invalid format. Only .jpg, .png, .gif and .svg are recognized",
			}

			content_tag :div, class: 'dropzone dropzone-default dz-clickable object contain max-w-100 max-h-100', data: data do
				yield
			end
		end
end
