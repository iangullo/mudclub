# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
# frozen_string_literal: true

# app/models/concerns/deprecated.rb
module Deprecated
	MODELS = {
		Stat:   %i[player for_players for_player by_player fetch(player_id:)],
		Event:  %i[players check_stats(player_id_key)],
		Team:   %i[players coaches],
		Sport:  %i[period_score(player_id:) set_period_score(player_id:)]
	}.freeze
	module_function
	def warn!(owner, method)
		Rails.deprecator.warn(
			"#{owner}##{method} is deprecated and will be removed in a future release"
		)
	end
end
