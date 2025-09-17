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
module PlayersHelper
	# return player part of definition for Player forms
	def player_form
		res = obj_club_selector(@player) + [
			gap_field(size: 5),
			{ kind: :label, value: I18n.t("player.number") },
			{ kind: :number_box, key: :number, min: 0, max: 99, size: 3, value: @player.number }
		]
		res << { kind: :hidden, key: :rdx, value: @rdx } if @rdx
		res << { kind: :hidden, key: :team_id, value: @teamid } if @teamid
		[ res ]
	end

	# nested form to add/edit player parents
	def player_form_parents
		res = [ [ { kind: :label, value: I18n.t("parent.many") } ] ]
		res << [
			{ kind: :nested_form, model: "player", key: "parents", child: Parent.create_new, row: "parent_row", cols: 2 }
		]
		res
	end

	# return table fields for players with team indicating
	# => nil: for players index
	# => Team: for team roster views
	def player_table(players:, team: nil)
		manage  = u_manager? || u_secretary? || team&.has_coach(u_coachid)
		title   = player_table_title(team:, manage:)
		rows    = Array.new
		players.each { | player|
			row = { url: player_path(player, team_id: team&.id, rdx: @rdx), items: [] }
			row[:items] << { kind: :normal, value: player.number, align: "center" }
			row[:items] << { kind: :normal, value: player.to_s(style: 0) }
			row[:items] << { kind: :normal, value: player.person&.age, align: "center" }
			if manage
				row[:items] << { kind: :contact, phone: player.person&.phone, device: device }
				row[:items] << symbol_field((player.all_pics? ? "yes" : "no"), align: "center", class: "border")
				row[:items] << symbol_field((player.active? ? "yes" : "no"), align: "center", class: "border")
				row[:items] << button_field({ kind: :delete, url: row[:url], name: player.to_s(style: 1), rdx: @rdx, confirm: true }) if team_manager?(team)
			end
			rows << row
		}
		{ title:, rows: }
	end

	# definition of fields to show for a player
	def player_show(team: nil)
		res = [ [] ]
		unless @player.person.age > 18 || @player.parents.empty?
			res << [ { kind: :label, value: "#{I18n.t("parent.many")}:", cols: 2 } ]
			@player.parents.each { |parent|
				res << [
					{ kind: :string, value: parent.to_s, cols: 2 },
					{ kind: :contact, email: parent&.person&.email, phone: parent&.person&.phone, device: device }
				]
			}
		end
		res << [ { kind: :subtitle, value: I18n.t("team.many") } ]
		res
	end


	# FieldComponents to show a @player
	def player_title
		person_show_title(@player, kind: :player)
	end

	private
		# title for a player table
		def player_table_title(team:, manage: false)
			title  = [
				{ kind: :normal, value: I18n.t("player.number"), align: "center" },
				{ kind: :normal, value: I18n.t("person.name") },
				{ kind: :normal, value: I18n.t("person.age"), align: "center" }
			]
			if manage
				title << { kind: :normal, value: I18n.t("person.phone_a"), align: "center" }
				title << { kind: :normal, value: I18n.t("person.pics"), align: "center" }
				title << { kind: :normal, value: I18n.t("status.active_a"), align: "center" }
				title << button_field({ kind: :add, url: new_player_path(team_id: team&.id, rdx: @rdx), frame: "modal" })
			end
			title
		end
end
