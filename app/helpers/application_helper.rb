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
module ApplicationHelper
	#-------------------------------------
	# Field Item wrappers for helpers/views
	#-------------------------------------

	# return definition of copyright field
	def copyright_item
		{ kind: :string, value: raw("&copy; 2025 iangullo@gmail.com"), align: "right", class: "text-xs text-gray-500" }
	end

	# Generic abstraction to pass FieldItemComponent definitions
	def field_item(kind:, key: nil, value: nil, **opts)
		{ kind:, key:, value: }.compact.merge(opts)
	end

	# standardised gap field defitinition
	def gap_item(size = nil, cols: nil, rows: nil)
		{ kind: :gap, size:, cols:, rows: }
	end

	# standardised gap row field definition
	def gap_row(size: 1, cols: 1, _class: "text-xs")
		[ { kind: :gap, size:, cols:, class: _class } ]
	end

	# standardised icon field definitions
	def icon_item(icon, align: nil, iclass: nil, cols: nil, rows: nil, size: nil, title: nil)
		{ kind: :icon, icon:, align:, class: iclass, cols:, rows:, size:, title: }
	end

	# regular label_item
	def label_item(value, **opts)
		{ kind: :label, value:, **opts }
	end

	# wrapper for :string item definitions
	def string_item(value, align: nil, cols: nil, rows: nil)
		{ kind: :string, value:, align:, cols:, rows: }
	end

	# standardised symbol field definitions.
	# f_opts: expects field options align:, cols:, rows:, class:
	# s_opts are options for the symbol itself (namespace and such)
	def symbol_item(concept, s_opts = {}, **f_opts)
		{ kind: :symbol,
			symbol: symbol_hash(concept, **s_opts),
			**f_opts
		}
	end

	def table_item(**options)
		options[:kind] ||= :table
		options
	end

	# return a :top_cell field definition
	def topcell_item(value, cols: nil, align: :center)
		{ kind: :top_cell, cols:, align:, value: }
	end

	#-------------------------------------
	# Button wrappers
	#-------------------------------------
	# standardised defintion button field wrapper
	def normal_button(button, **opts)
		field_item(kind: :button, button:, **opts)
	end

	def dropdown_button(button, **opts)
		field_item(kind: :dropdown, button:, **opts)
	end

	# common button to export to PDF
	def pdf_button(url)
		normal_button(
			{ kind: :link, symbol: symbol_hash(:pdf, size: "20x20"), url: },
			align: :center
		)
	end

	# file upload button
	def upload_button(key, label, value = nil, symbol: nil, **f_opts)
		{ kind: :upload, label:, key:, value:, **f_opts }
	end

	#-------------------------------------
	# Hidden form input definitions
	#-------------------------------------
	def hidden_input(key, value = nil, **opts)
		{ kind: :hidden, key:, value: }.merge(opts)
	end

	# Helper to turn nested hashes into a structured params definition:
	# e.g., {"person_attributes" => {"name" => "Rodrigo"}}
	def hidden_input_definitions(attrs, prefix: nil)
		fields = []

		attrs.each do |key, value|
			next if [ "authenticity_token", "button" ].include?(key.to_s)

			c_key = prefix ? "#{prefix}][#{key}" : key.to_s

			if value.is_a?(Hash) || value.is_a?(ActionController::Parameters)
				fields.concat(hidden_input_definitions(value, prefix: c_key))
			elsif value.is_a?(Array)
				value.each do |item|
					if item.is_a?(Hash) || item.is_a?(ActionController::Parameters)
						fields.concat(hidden_input_definitions(value, prefix: "#{current_key}][]"))
					else
						fields << hidden_input("#{current_key}][]", value)
					end
				end
			else
				field = hidden_input(c_key, value)
			end
			fields << field if field
		end

		fields
	end

	#-------------------------------------
	# General helpers for all views
	#-------------------------------------

	# return an html bulletized string from info
	def bulletize(info, indent: 1)
		bull = ""
		1.upto(indent) { bull += "&nbsp;&nbsp;" }
		bull += "&bull;&nbsp;"
		raw(bull + info)
	end

	# return device type
	def device
		agent = request.user_agent
		return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
		return "mobile" if agent =~ /Mobile/
		"desktop"
	end

	# standardised message wrapper
	def flash_message(message, kind = :info)
		{ message:, kind: }
	end

	# iconize an svg
	def svgicon(icon_name, options = {})
		file = File.read(Rails.root.join("app", "assets", "images", "#{icon_name}.svg"))
		doc = Nokogiri::HTML::DocumentFragment.parse file
		svg = doc.at_css "svg"

		options.each { |attr, value| svg[attr.to_s] = value }

		doc.to_html.html_safe
	end

	# prepare SVG symbol hash from the received fields
	def symbol_hash(concept, **options)
		options[:type] ||= :icon
		{ concept:, options: }
	end

	# generic title start defintion for views
	def title_start(icon:, title:, subtitle: nil, size: nil, rows: nil, cols: nil, _class: nil, form: nil)
		img  = { size:, rows:, class: _class }
		if form
			img[:kind]  = :image_box
			img[:key]   = "avatar"
			img[:value] = icon
		else
			img[:kind]  = :header_icon
			if icon.is_a? Hash
				img[:symbol] = icon
			else
				img[:icon] = icon
			end
		end
		res  = [ [ img, { kind: :title, value: title, cols: } ] ]
		res << [ { kind: :subtitle, value: subtitle, cols: } ] if subtitle
		res
	end
end
