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
module PlayersHelper
	# return icon and top of Player FieldsComponent
	def player_title_fields(title:, icon: "player.svg", rows: 2, cols: nil, form: nil)
		title_start(icon:, title:, rows:, cols:, size: "75x100", _class: "w-75 h-100 rounded align-top m-1", form:)
	end

	# return grid fields for players with obj indicating
	# => nil: for players index
	# => Team: for team roster views
	def player_grid(players:, obj: nil)
		p_ndx  = (obj == nil)
		retlnk = roster_team_path(obj) unless p_ndx
		title  = [
			{kind: "normal", value: I18n.t("player.number"), align: "center"},
			{kind: "normal", value: I18n.t("person.name")},
			{kind: "normal", value: I18n.t("person.age"), align: "center"},
			{kind: "normal", value: I18n.t("status.active_a"), align: "center"}
		]
		title << button_field({kind: "add", url: new_player_path(retlnk:, team_id: obj&.id), frame: "modal"}) if u_manager? or obj&.has_coach(u_coachid)
		rows = Array.new
		players.each { | player|
			retlnk = players_path(search: player.s_name) if p_ndx
			row    = {url: player_path(player, retlnk:), items: []}
			row[:items] << {kind: "normal", value: player.number, align: "center"}
			row[:items] << {kind: "normal", value: player.to_s}
			row[:items] << {kind: "normal", value: player.person.age, align: "center"}
			row[:items] << {kind: "icon", value: player.active? ? "Yes.svg" : "No.svg", align: "center"}
			row[:items] << button_field({kind: "delete", url: row[:url], name: player.to_s}) if u_manager?
			rows << row
		}
		return {title: title, rows: rows}
	end

	# FieldsComponent fields to show for a player
	def player_show_fields(team: nil)
		res = player_title_fields(title: I18n.t("player.single"), icon: @player.picture, rows: 3)
		res.last << {kind: "contact", email: @player.person.email, phone: @player.person.phone, device: device, rows: 3} unless u_playerid == @player.id
		res << [{kind: "label", value: @player.s_name}]
		res << [{kind: "label", value: @player.person.surname}]
		res << [obj_status_field(@player)]
		res.last << {kind: "string", value: @player.person.dni.to_s}
		res << [{kind: "gap"}, {kind: "string", value: @player.person.birthday}]
		if team
			att = @player.attendance(team: team)
			res << [
				{kind: "icon", value: "team.svg", size: "25x25"},
				{kind: "text", value: team.to_s}
			]
			res << [
				{kind: "label", value: I18n.t("match.many"), align: "right"},
				{kind: "text", value: att[:matches]}
			]
			res << [{kind: "icon-label", icon: "attendance.svg", label:  I18n.t("calendar.attendance"), cols: 3}]
			res << [
				{kind: "label", value: I18n.t("calendar.week"), align: "right"},
				{kind: "text", value: att[:last7].to_s + "%"}
			] if att[:last7]
			res << [
				{kind: "label", value: I18n.t("calendar.month"), align: "right"},
				{kind: "text", value: att[:last30].to_s + "%"}
			] if att[:last30]
			res << [
				{kind: "label", value: I18n.t("season.abbr"), align: "right"},
				{kind: "text", value: att[:avg].to_s + "%"}
			] if att[:avg]
		end
		unless @player.parents.empty?
			res << [{kind: "label", value: "#{I18n.t("parent.many")}:"}]
			@player.parents.each { |parent|
				res << [
					{kind: "string", value: parent.to_s},
					{kind: "contact", email: parent.person.email, phone: parent.person.phone, device: device}
				]
			}
		end
		res << [{kind: "subtitle", value: "#{I18n.t("team.many")}:"}]
		res
	end

	# return beginning FieldsComponent for Player forms
	def player_form_title(title:, rows: 3, cols: 2)
		res = player_title_fields(title:, icon: @player.picture, rows:, cols:, form: true)
		f_cols = cols>2 ? cols - 1 : nil
		res << [
			{kind: "label", value: I18n.t("person.name_a")},
			{kind: "text-box", key: :name, label: I18n.t("person.name"), value: @player.person.name, placeholder: I18n.t("person.name"), cols: f_cols}
		]
		res << [
			{kind: "label", value: I18n.t("person.surname_a")},
			{kind: "text-box", key: :surname, value: @player.person.surname, placeholder: I18n.t("person.surname"), cols: f_cols}
		]
		res << [
			{kind: "label-checkbox", label: I18n.t("sex.female_a"), key: :female, value: @player.person.female},
			{kind: "icon", value: "calendar.svg"},
			{kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @player.person.birthday, cols: f_cols}
		]
		res
	end

	# return first part of FieldsComponent for Player forms
	def player_form_fields_1(retlnk:, team_id:)
		[[
			{kind: "label-checkbox", label: I18n.t("status.active"), key: :active, value: @player.active},
			{kind: "gap", size: 8}, {kind: "label", value: I18n.t("player.number")},
			{kind: "number-box", key: :number, min: 0, max: 99, size: 3, value: @player.number},
			{kind: "hidden", key: :retlnk, value: retlnk},
			{kind: "hidden", key: :team_id, value: team_id}
		]]
	end

	# return personal data FieldsComponent for Player forms
	def player_form_person(person:)
		[
			[
				{kind: "label", value: I18n.t("person.pid_a"), align: "right"},
				{kind: "text-box", key: :dni, size: 8, value: person.dni, placeholder: I18n.t("person.pid")},
				{kind: "gap"}, {kind: "icon", value: "at.svg"},
				{kind: "email-box", key: :email, value: person.email, placeholder: I18n.t("person.email")}
			],
			[
				{kind: "icon", value: "user.svg"}, {kind: "text-box", key: :nick, size: 8, value: person.nick, placeholder: I18n.t("person.nick")},
				{kind: "gap"},
				{kind: "icon", value: "phone.svg"},
				{kind: "text-box", key: :phone, size: 12, value: person.phone, placeholder: I18n.t("person.phone")}
			]
		]
	end

	# nested form to add/edit player parents
	def player_form_parents
		res = [[{kind: "label", value: I18n.t("parent.many")}]]
		res << [
			{kind: "nested-form", model: "player", key: "parents", child: Parent.create_new, row: "parent_row", cols: 2}
		]
		res
	end
end
