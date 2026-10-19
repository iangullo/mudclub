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
module MomentsHelper
	# fields to tag a new moment of a match video
	def moment_form
		sport = @event.team.sport.name
		res   = title_start(icon: symbol_hash("video"), title: I18n.t("moment.add"), subtitle: @event.to_s)
		res << [
			symbol_field("clock", { title: I18n.t("moment.time") }),
			{ kind: :text_box, key: :time, value: @moment.time, placeholder: "12:34", size: 7, mandatory: { length: 1 } }
		]
		res << [
			symbol_field("player", { namespace: sport, title: I18n.t("player.single") }),
			{ kind: :select_box, key: :player_id, options: moment_player_list, value: @moment.player_id }
		]
		res << [ gap_field, { kind: :select_box, key: :kind, options: Moment.kind_list, value: @moment.kind } ]
		res << [ gap_field, { kind: :text_area, key: :note, value: @moment.note, placeholder: I18n.t("moment.note"), size: 30, lines: 3, mandatory: { length: 3 } } ]
		res
	end

	# colour of the badge for each kind of moment
	def moment_badge_class(moment)
		case moment.kind.to_sym
		when :good then "bg-green-100 text-green-800"
		when :improve then "bg-yellow-200 text-yellow-900"
		else "bg-gray-100 text-gray-700"
		end
	end

	# match roster (or whole team if no roster yet), preceded by a "whole team" option
	def moment_player_list
		players = @event.players.presence || @event.team.players
		[ [ I18n.t("moment.team"), "" ] ] + players.sort_by { |player| player.number.to_i }.map { |player| [ player.to_s, player.id ] }
	end
end
