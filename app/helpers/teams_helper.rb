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
module TeamsHelper
	# return FieldComponent for team view title
	def team_title_fields(title:, cols: nil, search: nil, edit: nil)
		res = title_start(icon: "team.svg", title: title, cols: cols)
		if search
			res << [{kind: "search-collection", key: :season_id, options: Season.real.order(start_date: :desc), value: @team ? @team.season_id : session.dig('team_filters', 'season_id')}]
		elsif edit and current_user.admin?
			res << [{kind: "select-collection", key: :season_id, options: Season.real, value: @team.season_id}]
		else
			res << [{kind: "label", value: @team.season.name}]
			w_l = @team.win_loss
			if w_l[:won]>0 or w_l[:lost]>0
				wlstr = "(" + w_l[:won].to_s + I18n.t("match.won") + " - " + w_l[:lost].to_s + I18n.t("match.lost") + ")"
				res << [{kind: "gap"}, {kind: "text", value: wlstr}]
			end
		end
		res
	end

	# return a GridComponent for the teams given
	def team_grid(teams:, season: nil, add_teams: false)
		if teams
			title = season ? [] : [{kind: "normal", value: I18n.t("season.abbr")}]
			title << {kind: "normal", value: I18n.t("team.single")}
			title << {kind: "normal", value: I18n.t("division.single")}
			title << {kind: "add", url: new_team_path, frame: "modal"} if add_teams
			rows = Array.new
			teams.each { |team|
				row = {url: team_path(team), items: []}
				row[:items] << {kind: "normal", value: team.season.name, align: "center"} unless season
				row[:items] << {kind: "normal", value: team.to_s}
				row[:items] << {kind: "normal", value: team.division.name, align: "center"}
				row[:items] << {kind: "delete", url: row[:url], name: team.to_s} if add_teams
				rows << row
			}
			{title: title, rows: rows}
		else
			nil
		end
	end

	# return HeaderComponent @fields for forms
	def team_form_fields(title:, cols: nil)
		res = team_title_fields(title:, cols:, edit: true)
		res << [{kind: "label", align: "right", value: I18n.t("person.name_a")}, {kind: "text-box", key: :name, value: @team.name}]
		res << [{kind: "icon", value: "category.svg"}, {kind: "select-collection", key: :category_id, options: Category.real, value: @team.category_id}]
		res << [{kind: "icon", value: "division.svg"}, {kind: "select-collection", key: :division_id, options: Division.real, value: @team.division_id}]
		res << [{kind: "icon", value: "location.svg"}, {kind: "select-collection", key: :homecourt_id, options: Location.home, value: @team.homecourt_id}]
		res << [{kind: "icon", value: "time.svg"}, {kind: "select-box", key: :rules, options: Category.time_rules, value: @team.periods }]
		res << [{kind: "icon", value: "coach.svg"}, {kind: "label", value:I18n.t("coach.many"), class: "align-center"}]
		res << [{kind: "gap"}, {kind: "select-checkboxes", key: :coach_ids, options: @eligible_coaches}]
		res
	end

	# return jump links for a team
	def team_links
		res = [[{kind: "jump", icon: "player.svg", url: roster_team_path(@team), label: I18n.t("team.roster"), frame: "modal", align: "center"}]]
		if (current_user.admin? or current_user.is_coach?)
			res.last << {kind: "jump", icon: "target.svg", url: targets_team_path(@team), label: I18n.t("target.many"), align: "center"}
			res.last << {kind: "jump", icon: "teamplan.svg", url: plan_team_path(@team), label: I18n.t("plan.abbr"), align: "center"}
		end
		res.last << {kind: "jump", icon: "timetable.svg", url: slots_team_path(@team), label: I18n.t("slot.many"), frame: "modal", align: "center"}
		if (current_user.admin? or @team.has_coach(current_user.person.coach_id))
			res.last << {kind: "edit", url: edit_team_path, size: "30x30", frame: "modal"}
		end
		res << [{kind: "gap"}]
		res
	end

	# A Field Component with grid for team attendance. obj is the parent oject (player/team)
	def team_attendance_grid
		t_att = @team.attendance
		if t_att # we have attendance data
			title = [{kind: "normal", value: I18n.t("player.number"), align: "center"}, {kind: "normal", value: I18n.t("person.name")}, {kind: "normal", value: I18n.t("calendar.week"), align: "center"}, {kind: "normal", value: I18n.t("calendar.month"), align: "center"}, {kind: "normal", value: I18n.t("season.abbr"), align: "center"}, {kind: "normal", value: I18n.t("match.many")}]
			rows  = Array.new
			m_tot = []
			@team.players.active.order(:number).each { |player|
				p_att = player.attendance(team: @team)
				row   = {url: player_path(player, retlnk: team_path(@team), team_id: @team.id), frame: "modal", items: []}
				row[:items] << {kind: "normal", value: player.number, align: "center"}
				row[:items] << {kind: "normal", value: player.to_s}
				row[:items] << {kind: "percentage", value: p_att[:last7], align: "right"}
				row[:items] << {kind: "percentage", value: p_att[:last30], align: "right"}
				row[:items] << {kind: "percentage", value: p_att[:avg], align: "right"}
				row[:items] << {kind: "normal", value: p_att[:matches], align: "center"}
				m_tot << p_att[:matches]
				rows << row
			}
			rows << {items: [{kind: "bottom", value: nil}, {kind: "bottom", align: "right", value: I18n.t("stat.average")}, {kind: "percentage", value: t_att[:sessions][:week], align: "right"}, {kind: "percentage", value: t_att[:sessions][:month], align: "right"}, {kind: "percentage", value: t_att[:sessions][:avg], align: "right"}, {kind: "normal", value: m_tot.sum/m_tot.size, align: "center"}]}
			return {title: title, rows: rows, chart: t_att[:sessions]}
		end
		return nil
	end
end
