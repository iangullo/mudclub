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

# Core shared component functions
class ApplicationComponent < ViewComponent::Base
	def initialize(tag: nil, classes: nil, **options)
		@tag = tag
		@classes = classes
		@options = options
	end

	def call
		content_tag(@tag, content, class: @classes, **@options) if @tag
	end

	private
	# handle errors gracefully
	def handle_error(error)
		# Log the error for debugging purposes
		Rails.logger.error("Error rendering button component: #{error.message}")

		# Render a fallback message or component
		content_tag(:div, "An error occurred while rendering this button.", class: "error-message")
	end

	# ensure symbol is converted to a proper symbol hash, if needed.
	def hashify_symbol(item)
		item[:symbol] = { concept: item[:symbol], options: {} } if item[:symbol].presence.is_a? String
		if item[:symbol]
			item[:symbol][:options] ||= {}
			item[:symbol][:options][:css]  ||= item[:css]
			item[:symbol][:options][:size] ||= item[:size]
		end
	end

	# unfied renderer for icon/symbol images
	def render_image(img, size: nil)
		return if img.blank? || !img.is_a?(Hash)
		html = ""
		if img[:symbol]
			img[:symbol][:options][:size] ||= size if size.present?
			html += render(SymbolComponent.new(img[:symbol][:concept], **img[:symbol][:options]))
		else
			img[:size] ||= img[:icon].present? ? "25x25" : size.presence
			html += image_tag(img[:value] || img[:icon], size: img[:size], class: img[:i_class], title: img[:title])
		end
		html.html_safe
	end

	# Return the value of a nested attribute accessed with flexible keys
	# Accepts either multiple arguments or an array of fallback keys (symbol or string).
	def safe_attr(opts, *keys)
		keys.flatten.each do |key|
			val = opts[key.to_s]
			return val if val.present?

			val = opts[key.to_sym]
			return val if val.present?
		end
		nil
	end

	# wrappers to generate different field tags - self-explanatory
	def table_tag(controller: nil, data: nil, classes: [], **table_options)
		table_options[:class] = [ "table-auto", *classes ].join(" ")
		if data.present?
			table_options[:data] = data
			table_options[:data][:controller] = controller if controller
		elsif controller
			table_options[:data] = { controller: controller }
		end
		content_tag(:table, table_options) do
			yield
		end
	end

	def tablerow_tag(data: nil, classes: [], **row_options)
		row_options[:data]  = data if data.present?
		row_options[:class] = classes.join(" ") unless classes.empty?
		content_tag(:tr, row_options) do
			yield
		end
	end

	def tablecell_tag(item, tag: :td)
		cell_options = {}
		cell_options[:data]    = item[:data] if item[:data].present?
		cell_options[:class]   = item[:class] if item[:class].present?
		cell_options[:align]   = item[:align] if item[:align].present?
		cell_options[:rowspan] = item[:rows] if item[:rows].present?
		cell_options[:colspan] = item[:cols] if item[:cols].present?
		content_tag(tag, cell_options) do
			yield
		end
	end

	# define a unique identifier for this Component
	def unique_identifier(label = "component")
		"#{label}-#{SecureRandom.uuid}"
	end
end
