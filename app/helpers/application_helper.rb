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
module ApplicationHelper
	def device
		agent = request.user_agent
		return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
		return "mobile" if agent =~ /Mobile/
		return "desktop"
	end

	def create_topbar
		TopbarComponent.new(user: user_signed_in? ? current_user : nil)
	end

	def svgicon(icon_name, options={})
		file = File.read(Rails.root.join('app', 'assets', 'images', "#{icon_name}.svg"))
		doc = Nokogiri::HTML::DocumentFragment.parse file
		svg = doc.at_css 'svg'

		options.each {|attr, value| svg[attr.to_s] = value}

		doc.to_html.html_safe
	end

	# generic title start FieldsComponent for views
	def title_start(icon:, title:, subtitle: nil, size: nil, rows: nil, cols: nil, _class: nil, form: nil)
		kind = form ? "image-box" : "header-icon"
		key  = form ? "avatar" : nil
		res  = [[
			{kind:, key:, value: icon, size: size, rows: rows, class: _class},
			{kind: "title", value: title, cols: cols}
		]]
		res << [{kind: "subtitle", value: subtitle}] if subtitle
		res
	end

	# file upload button
	def form_file_field(label:, key:, value:, cols: nil)
		[[{kind: "upload", label:, key:, value:, cols:}]]
	end

	# standardised message wrapper
	def flash_message(message, kind="info")
		res = {message: message, kind: kind}
	end

	# standardised FieldsComponent button field wrapper
	def button_field(button, cols: nil, rows: nil, align: nil, class: nil)
		{kind: "button", button: button, cols:, rows:, align:, class:}
	end

	# standardised generator of "active" label for user/player/coach
	def obj_status_field(obj)
		if obj&.active
			if obj.respond_to?(:number)
				{kind: "string", value: (I18n.t("player.number") + @player.number.to_s), align: "center"}
			else
				{kind: "string", value: I18n.t("status.active"),	align: "center"}
			end
		else
			{kind: "string", value: "(#{I18n.t("status.inactive")})",	dclass: "font-semibold text-gray-500 justify-center",	align: "center"}
		end
	end

	# wrappers to make code in all views/helpers more readable
	def u_admin?
		current_user.admin?
	end

	def u_manager?
		current_user.manager? || (current_user.admin? && current_user.is_coach?)
	end

	def u_coach?
		current_user.is_coach?
	end

	def u_player?
		current_user.is_player?
	end

	def u_coachid
		current_user.person.coach_id
	end

	def u_playerid
		current_user.person.player_id
	end

	def u_personid
		current_user.person.id
	end

	def u_userid
		current_user.id
	end
end
