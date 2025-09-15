# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
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
	def coach_form(team_id: nil, user: nil)
		res = obj_club_selector(@coach)
		res << { kind: :hidden, key: :team_id, value: team_id } if team_id
		res << { kind: :hidden, key: :user, value: true } if user
		res << { kind: :hidden, key: :rdx, value: @rdx } if @rdx
		[ res ]
	end

	# return table for @coaches TableComponent
	def coach_table(coaches: @coaches)
		editor = (u_manager? || u_secretary?)
		title  = [
			{ kind: :normal, value: I18n.t("person.name") },
			{ kind: :normal, value: I18n.t("person.contact") }
		]
		if editor
			title << { kind: :normal, value: I18n.t("person.pics"), align: "center" }
			title << { kind: :normal, value: I18n.t("status.active_a") }
			title << button_field({ kind: :add, url: new_coach_path(club_id: @clubid, rdx: @rdx), frame: "modal" })
		end

		rows = Array.new
		coaches.each { |coach|
			row = { url: coach_path(coach, rdx: @rdx), items: [] }
			row[:items] << { kind: :normal, value: coach.to_s }
			row[:items] << { kind: :contact, email: coach&.person&.email, phone: coach&.person&.phone, device: device }
			if editor
				row[:items] << symbol_field(coach.all_pics? ? "yes" : "no", align: "center")
				row[:items] << symbol_field(coach.active? ? "yes" : "no", align: "center")
				row[:items] << button_field({ kind: :delete, url: row[:url], name: coach.to_s })
			end
			rows << row
		}
		{ title:, rows: }
	end

	# FieldComponents to show a @coach
	def coach_title(team_id: nil)
		person_show_title(@coach, kind: :coach)
	end

	# FieldComponents to show a @coach
	def coach_show(team_id: nil, user: nil)
		res = club_manager? || u_coachid == @coach.id ? person_show(@coach.person) : [ [] ]
		unless @coach.teams.empty?
			res << [ { kind: :side_cell, value: (I18n.t("team.many")), align: "left" } ]
			res << [ { kind: :table, **team_table(teams: @coach.team_list) } ]
		end
		res
	end
end
