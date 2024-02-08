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
	# FieldsComponent fields to show for a player
	def player_show_fields(team: nil)
		res = person_show_fields(@player.person, title: I18n.t("player.single"), icon: @player.picture, cols: 3)
		res[4][0] = obj_status_field(@player)
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
		unless @player.person.age > 18 || @player.parents.empty?
			res << [{kind: "label", value: "#{I18n.t("parent.many")}:", cols: 2}]
			@player.parents.each { |parent|
				res << [
					{kind: "string", value: parent.to_s, cols: 2},
					{kind: "contact", email: parent.person.email, phone: parent.person.phone, device: device}
				]
			}
		end
		res << [{kind: "subtitle", value: "#{I18n.t("team.many")}:"}]
		res
	end

	# return player part of FieldsComponent for Player forms
	def player_form_fields(retlnk:, team_id:)
		[[
			{kind: "label-checkbox", label: I18n.t("status.active"), key: :active, value: @player.active},
			gap_field(size: 5),
			{kind: "label", value: I18n.t("player.number")},
			{kind: "number-box", key: :number, min: 0, max: 99, size: 3, value: @player.number},
			{kind: "hidden", key: :retlnk, value: retlnk},
			{kind: "hidden", key: :team_id, value: team_id}
		]]
	end

	# nested form to add/edit player parents
	def player_form_parents
		res = [[{kind: "label", value: I18n.t("parent.many")}]]
		res << [
			{kind: "nested-form", model: "player", key: "parents", child: Parent.create_new, row: "parent_row", cols: 2}
		]
		res
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
		title << {kind: "normal", value: I18n.t("person.pics"), align: "center"} if @team
		title << button_field({kind: "add", url: new_player_path(retlnk:, team_id: obj&.id), frame: "modal"}) if u_manager? or obj&.has_coach(u_coachid)
		rows = Array.new
		players.each { | player|
			retlnk = players_path(search: player.s_name) if p_ndx
			row    = {url: player_path(player, retlnk:), items: []}
			row[:items] << {kind: "normal", value: player.number, align: "center"}
			row[:items] << {kind: "normal", value: player.to_s}
			row[:items] << {kind: "normal", value: player.person.age, align: "center"}
			row[:items] << {kind: "icon", value: player.active? ? "Yes.svg" : "No.svg", align: "center"}
			row[:items] << {kind: "icon", value: player.all_pics? ? "Yes.svg" : "No.svg", align: "center"} if @team
			row[:items] << button_field({kind: "delete", url: row[:url], name: player.to_s}) if u_manager?
			rows << row
		}
		return {title: title, rows: rows}
	end
end
