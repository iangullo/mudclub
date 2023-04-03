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

	# home edit form fields
	def home_form_fields(club:)
		[
			[
				{kind: "header-icon", value: club.logo},
				{kind: "title", value: I18n.t("action.edit"), cols: 2}
			],
			[
				{kind: "label", value: I18n.t("person.name_a")},
				{kind: "text-box", key: :nick, value: club.nick}
			]
		]
	end
end
