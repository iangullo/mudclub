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
module PeopleHelper
	# return icon and top of FieldsComponent
	def person_title_fields(title:, icon: "person.svg", rows: 2, cols: 2, size: nil, _class: nil)
		title_start(icon: icon, title: title, rows: rows, cols: cols, size: size, _class: _class)
	end

	# FieldComponent fields to show a person
	def person_show_fields
		res = person_title_fields(title: I18n.t("person.single"), icon: @person.picture, size: "100x100", rows: 4, _class: "rounded-full")
		res << [{kind: "label", value: @person.s_name, cols: 3}]
		res << [{kind: "label", value: @person.surname, cols: 4}]
		res << [{kind: "string", value: @person.birthday, cols: 3}]
		res << [{kind: "string", value: @person.dni, align: "center"}]
		res.last << {kind: "contact-button", email: @person.email, phone: @person.phone, device: device}
		res << []
		res.last << {kind: "icon", value: "player.svg"} if @person.player_id > 0
		res.last << {kind: "icon", value: "coach.svg", align: "left"} if @person.coach_id > 0
		res
	end

	# return FieldsComponent @fields for forms
	def person_form_title(title:)
		res = person_title_fields(title:, icon: @person.picture, rows: 4, cols: 2, size: "100x100", _class: "rounded-full")
		res << [
			{kind: "label", value: I18n.t("person.name_a")},
			{kind: "text-box", key: :name, value: @person.name, placeholder: I18n.t("person.name")}
		]
		res << [
			{kind: "label", value: I18n.t("person.surname_a")},
			{kind: "text-box", key: :surname, value: @person.surname, placeholder: I18n.t("person.surname")}
		]
		res << [
			{kind: "icon", value: "calendar.svg"},
			{kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @person.birthday}
		]
		res << [{kind: "label-checkbox", label: I18n.t("sex.fem_a"), key: :female, value: @person.female, align: "center"}]
		res
	end

	def person_form_fields
		res = [
			[
				{kind: "label", value: I18n.t("person.pid_a"), align: "right"},
				{kind: "text-box", key: :dni, size: 8, value: @person.dni, placeholder: I18n.t("person.pid")},
				{kind: "gap"},
				{kind: "icon", value: "at.svg"},
				{kind: "email-box", key: :email, value: @person.email, placeholder: I18n.t("person.email")}
			],
			[
				{kind: "icon", value: "user.svg"},
				{kind: "text-box", key: :nick, size: 8, value: @person.nick, placeholder: I18n.t("person.nick")},
				{kind: "gap"},
				{kind: "icon", value: "phone.svg"},
				{kind: "text-box", key: :phone, size: 12, value: @person.phone, placeholder: I18n.t("person.phone")}
			]
		]
	end

	# return title for @people GridComponent
	def person_grid
		title = [{kind: "normal", value: I18n.t("person.name")}]
		title << button_field({kind: "add", url: new_person_path, frame: "modal"}) if u_admin?

		rows = Array.new
		@people.each { |person|
			row = {url: person_path(person), frame: "modal", items: []}
			row[:items] << {kind: "normal", value: person.to_s}
			row[:items] << button_field({kind: "delete", url: row[:url], name: person.to_s}) if u_admin?
			rows << row
		}
		{title: title, rows: rows}
	end
end
