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

# SortableComponent - attempt to standardise dynamic sortable lists as
#                   ViewComponent.
#		expected arguments:
#			model: name of parent object class
#			key: nested fields to populate
#			row: path to partial for each element to be rendered
#			order: attribute to order by the nested elements.
class SortableComponent < ApplicationComponent
	def initialize(form:, key:, order: :position, row:, id: nil)
		@form  = form
		@key   = key.to_sym
		@row   = row
		@order = order
		@id    = id || "sortable-#{@key}"
	end

	# generate html as a ruby call
	def call
		t_cls   = "draggable bg-gray-100 text-left text-gray-700 rounded-md hover:bg-gray-500 hover:text-indigo-100 focus:bg-indigo-900 focus:text-gray-200 focus:ring-blue-900"
		c_style = "display: grid; grid-template-columns: 1fr;"
		turbo_frame_tag(@id, class: "contents") do
			content_tag(:div, data: { controller: "sortable", "sortable-animation-value": 150 }, style: c_style) do
				children = @form.object.public_send(@key)
				children = children.order(@order) if @form.object.persisted? && children.respond_to?(:order)
				@form.fields_for(@key, children) do |ff|
					content_tag(:div, class: t_cls) do
						concat ff.hidden_field(:id)
						concat ff.hidden_field(:_destroy)
						concat ff.hidden_field(@order)
						concat render(@row, form: ff)
					end
				end
			end
		end
	end

	def render?
		@form.present? && @form.object.present?
	end
end
