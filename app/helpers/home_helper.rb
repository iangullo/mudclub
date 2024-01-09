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
module HomeHelper
	# default title FieldComponents for home page
	def home_title_fields
		title_start(icon: current_user.picture, title: current_user.s_name, _class: "rounded-full")
	end

	# fields for "about MudClub.." view
	def home_about_fields
		[
			[{kind: "gap", size: 1, cols: 2}],
			[{kind: "string", value: I18n.t("server.info-1"), cols: 2}],
			[{kind: "string", value: I18n.t("server.info-2"), cols: 2}],
			[{kind: "string", value: I18n.t("server.info-3"), cols: 2}],
			[{kind: "string", value: I18n.t("server.info-4"), cols: 2}],
			[{kind: "string", value: I18n.t("server.info-5"), cols: 2}],
			[button_field({kind: "jump", label: I18n.t("server.website"), url: "https://github.com/iangullo/mudclub/wiki", tab: true}, align: "right")],
			[{kind: "string", value: "(c) iangullo@gmail.com", align: "right", class: "text-sm text-gray-500"}],
		]
	end

	# title fields for admin pages
	def home_admin_title(title: current_user.to_s)
		[
			[{kind: "header-icon", value: "clublogo.svg"}, {kind: "title", value: "MudClub - #{I18n.t("action.admin")}"}],
			[{kind: "string", value: title}]
		]
	end

	# landing page for mudclub administrators
	def home_admin_fields
		res = home_admin_title
		res <<[
#			button_field({kind: "jump", icon: "location.svg", url: locations_path, label: I18n.t("location.many")}, align: "center"),
			button_field({kind: "jump", icon: "user.svg", url: users_path, label: I18n.t("user.many")}, align: "center")
		]
		res
	end

	# home edit form fields
	def home_form_fields(club:, retlnk: nil)
		res = [
			[
				{kind: "image-box", value: club.logo, rows: 3},
				{kind: "title", value: I18n.t("club.edit"), cols: 2}
			],
			[
				{kind: "label", value: I18n.t("person.name_a")},
				{kind: "text-box", key: :nick, value: club.nick, placeholder: "MudClub"}
			],
			[{kind: "gap", size: 1, cols: 2}]
		]
		res << {kind: "hidden", key: :retlnk, value: retlnk} if retlnk
		res
	end

	# user action log grid
	def home_actions_grid(actions:, retlnk: nil)
		title = [
			{kind: "normal", value: I18n.t("calendar.date"), align: "center"},
			{kind: "normal", value: I18n.t("user.single")},
			{kind: "normal", value: I18n.t("drill.desc")}
		]

		rows = []
		actions.each { |action|
			url = action.url.present? ? action.url : "#"
			frm = action.modal ? "modal" : "_top"
			row = {url:, frame: frm, items: []}
			row[:items] << {kind: "normal", value: action.date_time}
			row[:items] << {kind: "normal", value: action.user.to_s}
			row[:items] << {kind: "normal", value: action.description}
			rows << row
		}
		{title:, rows:}
	end
end
