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
	# return Coach-specific form fields
	def coach_form_fields
		res = [{kind: "label-checkbox", label: I18n.t("status.active"), key: :active, value: @coach.active}]
		res << {kind: "hidden", key: :retlnk, value: @retlnk} if @retlnk
		return [res]
	end

	# return grid for @coaches GridComponent
	def coach_grid
		title = [
			{kind: "normal", value: I18n.t("person.name")},
			{kind: "normal", value: I18n.t("person.contact")}
		]
		if u_manager?
			title << {kind: "normal", value: I18n.t("person.pics"), align: "center"}
			title << {kind: "normal", value: I18n.t("status.active_a")}
			title << button_field({kind: "add", url: new_coach_path, frame: "modal"})
		end

		rows = Array.new
		@coaches.each { |coach|
			row = {url: coach_path(coach, retlnk: @retlnk), items: []}
			row[:items] << {kind: "normal", value: coach.to_s}
			row[:items] << {kind: "contact", email: coach.person.email, phone: coach.person.phone, device: device}
			if u_manager?
				row[:items] << {kind: "icon", value: coach.all_pics? ? "Yes.svg" : "No.svg", align: "center"} 
				row[:items] << {kind: "icon", value: coach.active? ? "Yes.svg" : "No.svg", align: "center"}
				row[:items] << button_field({kind: "delete", url: row[:url], name: coach.to_s})
			end
			rows << row
		}
		{title:, rows:}
	end

	# FieldComponents to show a @coach
	def coach_show_fields
		res = person_show_fields(@coach.person, title: I18n.t("coach.single"), icon: @coach.picture)
		res[4][0] = obj_status_field(@coach)
		res << [{kind: "side-cell", value: (I18n.t("team.many")), align: "left"}]
	end
end
