# MudClub - Simple Rails app to manage a team sports club.
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

# NestedComponent - attempt to standardise dynamic nested_form_fields as
#                   ViewComponent.
#		expected arguments:
#			model: name of parent object class
#			key: nested fields to populate
#			child: object instance to use for new objects to be added to collection
#			row: path to partial for each element to be rendered
#			filter: filter objects to be displayed - Hash of key-value pairs
#			order: attribute to order by the nested elements.
#			btn_add: definition of button to add new elements.
class NestedComponent < ApplicationComponent
	def initialize(model:, key:, form:, child:, row:, filter: nil, order: nil)
		@model   = model
		@form    = form
		@child   = child
		@key     = key.to_sym
		@row     = row
		@filter  = normalize_filter(filter)
		@order   = order ? order.to_sym : nil
		@btn_del = ButtonComponent.new(kind: :remove)
		@btn_add = ButtonComponent.new(kind: :add_nested)
	end

	private
		# filter collection of objects using filter hash
		def normalize_filter(filter)
			filter.is_a?(Hash) ? filter : nil
		end

		def get_children
			return nil unless @form

			children = @form.object.send(@key)
			children = children.order(@order) if @order
			children = children.select do |child|
				@filter.nil? || @filter.all? { |k, v| child.send(k) == v }
			end
			children
		end

		# prepare the placeholder template
		def prepare_template
			view_context.capture do
				@form.fields_for @key, @child, child_index: "NEW_RECORD" do |ff|
					render_row(ff)
				end
			end
		end

		def prepare_collection
			view_context.capture do
				@form.fields_for @key, get_children do |ff|
					render_row(ff)
				end
			end
		end

		# This renders the row markup inline
		def render_row(ff)
			view_context.content_tag(:div, class: "flex w-full items-center", data: { nested_form_target: "item", new_record: ff.object.new_record? }) do
				view_context.safe_join([
					render(@row, form: ff),
					render(@btn_del),
					ff.hidden_field(:id),
					ff.hidden_field(:_destroy)
				])
			end
		end
end
