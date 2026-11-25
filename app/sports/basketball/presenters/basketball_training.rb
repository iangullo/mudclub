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
# Presentation helpers for Basketball training sessions
module Presenters
	class BasketballTraining
		def initialize(sport)
			@sport = sport
		end

		def show(event, athlete_id:)
			stats = Stat.fetch(event_id: event.id, period: 0, athlete_id:, create: false)
			res   = header
			res << show_shooting_data(s_label("ft"), stats, :ftm, :fta)
			res << show_shooting_data(s_label("tz"), stats, :tzm, :tza)
			res << show_shooting_data(s_label("tm"), stats, :tmm, :tma)
			res << show_shooting_data(s_label("t3"), stats, :t3m, :t3a)
			Stats::BasketballCalculator.new(@sport).compute_shooting_totals(event.id, athlete_id, stats)
			res << show_shooting_data(UI::Stat.fld(:total, :short), stats, :fgm, :fga)
			res
		end

		def form(event, athlete_id:)
			key   = "#{athlete_id}_0_"
			stats = Stat.fetch(event_id: event.id, athlete_id:)
			res   = header
			res << form_shooting_data(key, s_label("ft"), stats, :ftm, :fta)
			res << form_shooting_data(key, s_label("tz"), stats, :tzm, :tza)
			res << form_shooting_data(key, s_label("tm"), stats, :tmm, :tma)
			res << form_shooting_data(key, s_label("t3"), stats, :t3m, :t3a)
			res
		end

		private
			def header
				res = [ [ { kind: :gap }, { kind: :side_cell, value: @sport.t_path("training.stats.plural"), align: "middle", cols: 5 } ] ]
				res << [
					{ kind: :gap },
					topcell(@sport.t_path(:shot, :many)),
					topcell(@sport.t_path(:shot, :scored)),
					topcell("/"),
					topcell(@sport.t_path(:shot, :attempt))
				]
			end

			def s_label(stat, short: true)
				tail = short ? "_short" : ""
				@sport.t_path(:stats, "#{stat}#{tail}".to_sym)
			end

			def topcell(value, cols: nil, rows: nil, align: :center)
				{ kind: :top_cell, cols:, rows:, align:, value: }
			end

			def show_shooting_data(label, stats, scored, attempts)
				s_key = @sport.statistics.enum[scored]
				a_key = @sport.statistics.enum[attempts]
				made  = Stat.fetch(concept: s_key, period: 0, stats:).first&.value.to_i
				taken = Stat.fetch(concept: a_key, period: 0, stats:).first&.value.to_i
				pctg  = taken > 0 ? (made * 100 / taken) : "N/A"
				pcol  = taken == 0 ? "gray-300" : (pctg < 20 ? "red-900" : (pctg < 50 ? "yellow-700" : (pctg < 70 ? "gray-700" : "green-700")))
				[
					{ kind: :gap },
					@sport.stat_label(label),
					{ kind: :string, value: made, class: "border px-1 py-1", align: :right },
					@sport.label_item("/"),
					{ kind: :string, value: taken, class: "border px-1 py-1", align: :right },
					{ kind: :text, value: (taken == 0 ? pctg : "#{pctg}%"), class: "align-middle text-#{pcol}", align: :center }
				]
			end

			def form_shooting_data(key, label, stats, scored, attempts)
				k_made  = @sport.statistics.enum[scored]
				v_made  = Stat.fetch(concept: k_made, stats:).first&.value.to_i
				k_taken = @sport.statistics.enum[attempts]
				v_taken = Stat.fetch(concept: k_taken, stats:).first&.value.to_i
				[
					{ kind: :gap },
					@sport.stat_label(label),
					{ kind: :number_box, key: "#{key}#{k_made}", value: v_made, class: "shots-made border px-1 py-1", align: :right, size: 1 },
					@sport.label_item("/"),
					{ kind: :number_box, key: "#{key}#{k_taken}", value: v_taken, class: "shots-taken border px-1 py-1", align: :right, size: 1 }
				]
			end
	end
end
