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
	def home_title_fields(icon: current_user.picture, title: current_user.s_name, subtitle: nil)
		title_start(icon:, title:, subtitle:, _class: "rounded-full")
	end

	# fields for "about MudClub.." view
	def home_about_title
		build = "(#{I18n.t("server.build")}#{BUILD})"
		res   = title_start(icon: "mudclub.svg", title: "MudClub #{VERSION}")
		res << [{kind: "string", value: build, class: "text-sm text-gray-500"}]
		res << [
			button_field({kind: "link", label: I18n.t("server.about"), url: "https://github.com/iangullo/mudclub/wiki", tab: true}, cols: 2)
		]
	end
		# fields for "about MudClub.." view
	def home_about_fields
		[
			[{kind: "string", value: I18n.t("server.info-1")}],
			[{kind: "string", value: I18n.t("server.info-2")}],
			[{kind: "string", value: bulletize(I18n.t("server.info-3"))}],
			[{kind: "string", value: bulletize(I18n.t("server.info-4"))}],
			[{kind: "string", value: bulletize(I18n.t("server.info-5"))}],
			[{kind: "string", value: bulletize(I18n.t("server.info-6"))}],
			gap_row,
			[copyright_field],
			[{kind: "string", value: I18n.t("server.published"), align: "right", class: "text-sm text-gray-500"}]
		]
	end

	# title fields for admin pages
	def home_admin_title(icon: "mudclub.svg", title: current_user.to_s)
		[
			[{kind: "header-icon", value: icon}, {kind: "title", value: "MudClub - #{I18n.t("action.admin")}"}],
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
			gap_row(cols: 2)
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
