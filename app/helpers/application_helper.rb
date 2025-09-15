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
module ApplicationHelper
	# standardised defintion button field wrapper
	def button_field(button, cols: nil, rows: nil, align: nil, class: nil)
		{ kind: :button, button:, cols:, rows:, align:, class: }
	end

	# return an html bulletized string from info
	def bulletize(info, indent: 1)
		bull = ""
		1.upto(indent) { bull += "&nbsp;&nbsp;" }
		bull += "&bull;&nbsp;"
		raw(bull + info)
	end

	# return definition of copyright field
	def copyright_field
		{ kind: :string, value: raw("&copy; 2025 iangullo@gmail.com"), align: "right", class: "text-xs text-gray-500" }
	end

	# return device type
	def device
		agent = request.user_agent
		return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
		return "mobile" if agent =~ /Mobile/
		"desktop"
	end

	# file upload button
	def form_file_field(label:, key:, value:, cols: nil)
		[ [ { kind: :upload, label:, key:, value:, cols: } ] ]
	end

	# standardised message wrapper
	def flash_message(message, kind = :info)
		{ message:, kind: }
	end

	# standardised gap row field definition
	def gap_field(size: nil, cols: nil, rows: nil)
		{ kind: :gap, size:, cols:, rows: }
	end

	def grid_field(items, form: nil, cols: 1)
		{ kind: :grid, items:, form:, cols: }
	end

	# standardised icon field definitions
	def icon_field(icon, align: nil, iclass: nil, cols: nil, rows: nil, size: nil, title: nil)
		{ kind: :icon, icon:, align:, class: iclass, cols:, rows:, size:, title: }
	end

	# standardised gap row field definition
	def gap_row(size: 1, cols: 1, _class: "text-xs")
		[ { kind: :gap, size:, cols:, class: _class } ]
	end

	# Field to use in forms to select club of a user/player/coach/team
	def obj_club_selector(obj)
		[
			{ kind: :icon, icon: "mudclub.svg", title: I18n.t("club.single") },
			{ kind: :select_box, align: "left", key: :club_id, options: current_user.club_list, value: obj.club_id, cols: 4 }
		]
	end

	# standardised generator of "active" label for user/player/coach
	def obj_status_field(obj)
		if obj&.active?
			case obj
			when Coach
				I18n.t("coach.abbr")
			when Player
				I18n.t("player.number") + @player.number.to_s
			else
				""
			end
			icon_field(obj.club.logo, title: obj.club.nick, align: "center")
		else
			{ kind: :string, value: "(#{I18n.t("status.inactive")})",	dclass: "font-semibold text-gray-500 justify-center",	align: "center" }
		end
	end

	# common button to export to PDF
	def pdf_button(url)
		button_field({
				kind: :link,
				symbol: symbol_hash("pdf", size: "20x20"),
				url:
			},
			align: "center"
		)
	end

	# wrapper for :string field definitions
	def string_field(value, align: nil, cols: nil, rows: nil)
		{ kind: :string, value:, align:, cols:, rows: }
	end

	# iconize an svg
	def svgicon(icon_name, options = {})
		file = File.read(Rails.root.join("app", "assets", "images", "#{icon_name}.svg"))
		doc = Nokogiri::HTML::DocumentFragment.parse file
		svg = doc.at_css "svg"

		options.each { |attr, value| svg[attr.to_s] = value }

		doc.to_html.html_safe
	end

	# standardised symbol field definitions.
	# f_opts: expects field options align:, cols:, rows:, class:
	# s_opts are options for the symbol itself (namespace and such)
	def symbol_field(concept, s_opts = {}, **f_opts)
		{ kind: :symbol,
			symbol: symbol_hash(concept, **s_opts),
			**f_opts
		}
	end

	# prepare SVG symbol hash from the received fields
	def symbol_hash(concept, **options)
		options[:type] ||= :icon
		{ concept:, options: }
	end

	def table_field(**options)
		options[:kind] ||= :table
		options
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

	# return a :top_cell field definition
	def topcell_field(value, cols: nil, align: "center")
		{ kind: :top_cell, cols:, align:, value: }
	end
end
