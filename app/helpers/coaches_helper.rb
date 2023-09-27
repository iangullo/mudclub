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
module CoachesHelper
	# return icon and top of FieldsComponent
	def coach_title(title:, icon: "coach.svg", rows: 2, cols: nil, _class: nil, form: nil)
		title_start(icon: icon, title: title, rows: rows, size: "75x100", cols: cols, _class: "w-75 h-100 rounded align-top m-1", form:)
	end

	# FieldComponents to show a @coach
	def coach_show_fields
		res = coach_title(title: I18n.t("coach.single"), icon: @coach.picture, rows: 3)
		res.last << {kind: "contact", email: @coach.person.email, phone: @coach.person.phone, device: device, rows: 3} unless u_coachid == @coach.id
		res << [{kind: "label", value: @coach.s_name}]
		res << [{kind: "label", value: @coach.person.surname}]
		res << [obj_status_field(@coach)]
		res.last << {kind: "string", value: @coach.person.dni.to_s}
		res << [{kind: "gap"}, {kind: "string", value: @coach.person.birthday}]
		res << [{kind: "side-cell", value: (I18n.t("team.many")), align: "left"}]
	end

	# return FieldsComponent @fields for forms
	def coach_form_title(title:, rows: 3, cols: 2)
		res = coach_title(title:, icon: @coach.picture, rows: rows, cols: cols, form: true)
		f_cols = cols>2 ? cols - 1 : nil
		res << [
			{kind: "label", value: I18n.t("person.name_a")},
			{kind: "text-box", key: :name, value: @coach.person.name, placeholder: I18n.t("person.name"), cols: f_cols}
		]
		res << [
			{kind: "label", value: I18n.t("person.surname_a")},
			{kind: "text-box", key: :surname, value: @coach.person.surname, placeholder: I18n.t("person.surname"), cols: f_cols}
		]
		res << [
			{kind: "icon", value: "calendar.svg"},
			{kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @coach.person.birthday, cols: f_cols}
		]
	end

	# return Coach-specific form fields
	def coach_form_fields
		[[{kind: "label-checkbox", label: I18n.t("status.active"), key: :active, value: @coach.active, cols: 4}]]
	end

	# return FieldsComponent @fields for forms
	def coach_person_fields
		person = @coach.person
		[
			[
				{kind: "label", value: I18n.t("person.pid_a"), align: "right"},
				{kind: "text-box", key: :dni, size: 8, value: person.dni, placeholder: I18n.t("person.pid")},
				{kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: person.email, placeholder: I18n.t("person.email")}],
			[
				{kind: "icon", value: "user.svg"},
				{kind: "text-box", key: :nick, size: 8, value: person.nick, placeholder: I18n.t("person.nick")},
				{kind: "gap"}, {kind: "icon", value: "phone.svg"}, {kind: "text-box", key: :phone, size: 12, value: person.phone, placeholder: I18n.t("person.phone")}]
		]
	end

	# return grid for @coaches GridComponent
	def coach_grid
		title = [
			{kind: "normal", value: I18n.t("person.name")},
			{kind: "normal", value: I18n.t("person.age")},
			{kind: "normal", value: I18n.t("status.active_a")}
		]
		title << button_field({kind: "add", url: new_coach_path, frame: "modal"}) if u_manager?

		rows = Array.new
		@coaches.each { |coach|
			row = {url: coach_path(coach), frame: "modal", items: []}
			row[:items] << {kind: "normal", value: coach.to_s}
			row[:items] << {kind: "normal", value: coach.person.age, align: "center"}
			row[:items] << {kind: "icon", value: coach.active? ? "Yes.svg" : "No.svg", align: "center"}
			row[:items] << button_field({kind: "delete", url: row[:url], name: coach.to_s}) if u_manager?
			rows << row
		}
		{title: title, rows: rows}
	end
end
