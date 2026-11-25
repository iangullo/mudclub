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
# Manage Basketball Rules
module Rules
	class BasketballConfig
		DEFAULT_LIMITS = {
			fiba:  { roster: { max: 16, min: 5 }, playing: { max: 5, min: 2 }, periods: { regular: 4, extra: 10 }, duration: { regular: 600, extra: 300 } },
			u14:   { roster: { max: 16, min: 5 }, playing: { max: 5, min: 2 }, outings: { first: 3, max: 2, min: 1 }, periods: { regular: 4, extra: 10 }, duration: { regular: 600, extra: 300 } },
			u12:   { roster: { max: 16, min: 5 }, playing: { max: 5, min: 2 }, outings: { first: 5, max: 3, min: 2 }, periods: { regular: 6, extra: 10 }, duration: { regular: 480, extra: 300 } },
			u10:   { roster: { max: 16, min: 5 }, playing: { max: 5, min: 2 }, outings: { first: 3, max: 2, min: 1 }, periods: { regular: 4, extra: 10 }, duration: { regular: 600, extra: 300 } },
			u8:    { roster: { max: 16, min: 5 }, playing: { max: 4, min: 2 }, outings: { first: 3, max: 2, min: 1 }, periods: { regular: 4, extra: 10 }, duration: { regular: 480, extra: 300 } },
			three: { roster: { max: 5,  min: 3 }, playing: { max: 3, min: 2 }, periods: { regular: 1, extra: 10 }, duration: { regular: 420, extra: 180 } }
		}.freeze

		def initialize(sport)
			@sport = sport
		end

		def default_rules(category)
			case category.age
			when 0..8   then @sport.rules[:u8]
			when 9..10  then @sport.rules[:u10]
			when 11..12 then @sport.rules[:u12]
			when 13..14 then @sport.rules[:u14]
			else             @sport.rules[:fiba]
			end
		end

		def match_periods(rule)
			config = @sport.limits_for(rule)
			return nil unless config

			periods = config[:periods] || config["periods"]
			periods && (periods[:regular] || periods["regular"])
		end

		def match_outings(rule)
			config = @sport.limits_for(rule)
			return nil unless config

			outings = config[:outings] || config["outings"]
			return nil unless outings

			periods = config[:periods] || config["periods"]

			{
				total: periods[:regular] || periods["regular"],
				first: outings[:first]   || outings["first"],
				min:   outings[:min]     || outings["min"],
				max:   outings[:max]     || outings["max"]
			}
		end

		def rules_limits
			res    = rules_limits_title
			limits = @sport.limits
			@sport.rules.enum.each_key do |rule|
				res << rules_limits_row(rule, limits[rule])
			end
			res
		end

		private
			def topcell(value, cols: nil, rows: nil, align: :center)
				{ kind: :top_cell, cols:, rows:, align:, value: }
			end

			def rules_limits_title
				k_max = UI::Stat.fld(:max, :short)
				k_min = UI::Stat.fld(:min, :short)
				k_qty = UI::Stat.fld(:max, :short)

				[
					[
						topcell(@sport.fld(:rules), rows: 3),
						topcell(@sport.term(:period, :plural), cols: 4),
						topcell(Team.fld(:roster), cols: 2, rows: 2),
						topcell(@sport.t_path(:outings, :playing), cols: 2, rows: 2),
						topcell(@sport.t_path(:outings, :quarter), cols: 3, rows: 2)
					],
					[
						topcell(@sport.t_path(:periods, :regular), cols: 2),
						topcell(@sport.t_path(:periods, :extra), cols: 2)
					],
					[
						topcell(@sport.term(:period, :short)),
						topcell(k_qty),
						topcell(@sport.t_path(:periods, :values, :ot_short)),
						topcell(k_qty),
						topcell(k_max),
						topcell(k_min),
						topcell(k_max),
						topcell(k_min),
						topcell(@sport.t_path(:outings, :first)),
						topcell(k_max),
						topcell(k_min)
					]
				]
			end

			def rules_limits_row(rule, limit)
				g_cls  = "border"
				n_cls  = "#{g_cls} text-center"
				r_per  = limit[:periods]
				r_dur  = limit[:duration]
				r_ros  = limit[:roster]
				r_play = limit[:playing]
				r_out  = limit[:outings] || { first: "N/A", min: "N/A", max: "N/A" }
				[
					{ kind: :normal, value: @sport.t_path(:rules, :values, rule), class: g_cls },
					{ kind: :normal, value: r_per[:regular], class: n_cls },
					{ kind: :normal, value: r_dur[:regular] / 60, class: n_cls },
					{ kind: :normal, value: r_per[:extra], class: n_cls },
					{ kind: :normal, value: r_dur[:extra] / 60, class: n_cls },
					{ kind: :normal, value: r_ros[:max], class: n_cls },
					{ kind: :normal, value: r_ros[:min], class: n_cls },
					{ kind: :normal, value: r_play[:max], class: n_cls },
					{ kind: :normal, value: r_play[:min], class: n_cls },
					{ kind: :normal, value: r_out[:first] || r_out["first"], class: n_cls },
					{ kind: :normal, value: r_out[:max]   || r_out["max"], class: n_cls },
					{ kind: :normal, value: r_out[:min]   || r_out["min"], class: n_cls }
				]
			end
	end
end
