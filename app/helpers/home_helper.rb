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


	# title fields for admin pages
	def home_admin_title
		[
			[{kind: "header-icon", value: "clublogo.svg"}, {kind: "title", value: "MudClub - #{I18n.t("action.admin")}"}],
			[{kind: "string", value: current_user.to_s}]
		]
	end

	# landing page for mudclub administrators
	def home_admin_fields
		res = home_admin_title
		res <<[
			button_field({kind: "jump", icon: "location.svg", url: locations_path, label: I18n.t("location.many")}, align: "center"),
			button_field({kind: "jump", icon: "user.svg", url: users_path, label: I18n.t("user.many")}, align: "center")
		]
		res
	end

	# home edit form fields
	def home_form_fields(club:, retlnk: nil)
		res = [
			[
				{kind: "header-icon", value: club.logo},
				{kind: "title", value: I18n.t("action.edit"), cols: 2}
			],
			[
				{kind: "label", value: I18n.t("person.name_a")},
				{kind: "text-box", key: :nick, value: club.nick, placeholder: "MudClub"}
			]
		]
		res << {kind: "hidden", key: :retlnk, value: retlnk} if retlnk
		res
	end
end
