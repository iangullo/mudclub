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
	def person_title_fields(title:, icon: "person.svg", rows: 2, cols: nil, size: "75x100", _class: "w-75 h-100 rounded align-top m-1", form: nil)
		title_start(icon:, title:, rows:, cols:, size:, _class: _class, form:)
	end

	# FieldComponent fields to show a person
	def person_show_fields(person, title: I18n.t("person.single"), icon: @person.picture, rows: 3)
		res = person_title_fields(title:, icon:, rows:, cols: 2)
		res << [{kind: "label", value: person.s_name, cols: 2}]
		res << [{kind: "label", value: person.surname, cols: 2}]
		res << [{kind: "contact", email: person.email, phone: person.phone, device: device, align: "center"}, {kind: "string", value: person.dni}]
		res << [{kind: "gap", size: 1}, {kind: "string", value: person.birthday}]
		res << [
			{kind: "icon", value: "home.svg", class: "align-top"},
			{kind: "string", value: simple_format("#{person.address}"), align: "left", cols: 2}
		] if person.address.present?
		res
	end

	# return FieldsComponent @fields for forms
	def person_form_title(person, icon: person.picture, title:, cols: 2, sex: nil)
		res = person_title_fields(title:, icon:, rows: (sex ? 3 : 4), cols:, form: true)
		res << [
			{kind: "label", value: I18n.t("person.name_a")},
			{kind: "text-box", key: :name, value: person.name, placeholder: I18n.t("person.name")}
		]
		res << [
			{kind: "label", value: I18n.t("person.surname_a")},
			{kind: "text-box", key: :surname, value: person.surname, placeholder: I18n.t("person.surname")}
		]
		res << (sex ? [{kind: "label-checkbox", label: I18n.t("sex.female_a"), key: :female, value: person.female, align: "center"}] : [])
		res.last << {kind: "icon", value: "calendar.svg"}
		res.last << {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: person.birthday}
		res
	end

	def person_form_fields(person=@person)
		res = [
			[
				{kind: "label", value: I18n.t("person.pid_a"), align: "right"},
				{kind: "text-box", key: :dni, size: 8, value: person.dni, placeholder: I18n.t("person.pid")},
				{kind: "gap"},
				{kind: "icon", value: "phone.svg"},
				{kind: "text-box", key: :phone, size: 12, value: person.phone, placeholder: I18n.t("person.phone")}
			],
			[
				{kind: "icon", value: "user.svg"},
				{kind: "text-box", key: :nick, size: 8, value: person.nick, placeholder: I18n.t("person.nick")},
				{kind: "gap"},
				{kind: "icon", value: "at.svg"},
				{kind: "email-box", key: :email, value: person.email, placeholder: I18n.t("person.email")}
			],
			[
				{kind: "icon", value: "home.svg", class: "align-top"},
				{kind: "text-area", key: :address, size: 34, cols: 4, lines: 2, value: person.address, placeholder: I18n.t("person.address")},
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
