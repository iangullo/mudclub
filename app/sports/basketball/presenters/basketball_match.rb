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
# Presentation helpers for Basketball matches
module Presenters
	class BasketballMatch
		def initialize(sport)
			@sport = sport
		end

		def outings_table(event, outings, edit: false, rdx: nil)
			title = [
				{ kind: :normal, value: Assignment.fld(:number, :short), align: :center },
				{ kind: :normal, value: Person.fld(:name) }
			]
			rows       = []
			kind       = (edit ? :text : :normal)
			e_stats    = event.stats
			raw_rule   = event.team.category.rules
			t_rules    = raw_rule.is_a?(Integer) ? @sport.rules.key(raw_rule) : raw_rule&.to_sym
			config     = @sport.limits[t_rules] || {}
			data       = (config[:outings] || {}).dup
			data[:tot] = config.dig(:periods, :regular)
			data[:act] = config.dig(:playing, :max)
			return nil if data.empty? || data[:tot].nil?

			if @sport.periods
				q_athletes = {}
				1.upto(outings[:total]) do |i|
					title << { kind: :normal, value: @sport.t_path(:periods, :values, "q#{i}_short".to_sym) }
					q_athletes[i] = 0
				end
			end

			event.athletes.each do |athlete|
				a_outings = 0
				a_stats   = Stat.fetch(kind: :athlete, athlete_id: athlete.id, stats: e_stats, create: false)
				row       = { items: [] }
				unless edit
					row[:url]   = event.attendee_url(athlete, rdx:)
					row[:frame] = :modal
				end
				row[:items] << { kind:, value: athlete.number.to_s, align: :center }
				row[:items] << { kind:, value: athlete.s_name }
				1.upto(outings[:total]) do |q|
					q_val = Stat.fetch(period: q, stats: a_stats, create: false).first&.value.to_i
					if edit
						row[:items] << { kind: :checkbox_q, key: :outings, athlete_id: athlete.id, q: "q#{q}", value: q_val, align: :center, data: { columnId: "q#{q}" } }
					elsif q_val == 1
						a_outings     += 1 if q <= data[:first]
						q_athletes[q] += 1
						row[:items] << { kind: :symbol, symbol: { concept: "yes", options: {} }, class: "" }
					else
						row[:items] << { kind: :gap, size: 1, class: "border px-1 py-1" }
					end
				end
				row[:classes] = (a_outings < data[:min]) || (a_outings > data[:max]) ? [ "border", "px-1", "py-1", "bg-red-300" ] : []
				rows << row
			end

			unless edit
				1.upto(outings[:total]) do |i|
					if q_athletes[i] != data[:act]
						rows.each { |row| row[:items][1 + i][:class] += " bg-red-300" }
					end
				end
			end

			{ title:, rows:, data:, controller: "outings" }
		end

		def stats_table(event, edit: false, rdx: nil)
			head    = match_stats_header(edit:)
			rows    = []
			e_stats = event.stats
			event.athletes.each do |athlete|
				a_stats     = Stat.fetch(athlete_id: athlete.id, period: 0, stats: e_stats, create: false)
				row         = { items: [] }
				row[:url]   = event.attendee_url(athlete, rdx:) unless edit
				row[:frame] = :modal
				row[:items] = match_stats_row(athlete, a_stats, edit:)
				rows << row
			end
			{ title: head, rows: rows }
		end

		def match_fields(event, edit: false, new: false)
			gender = event.team.category.female? ? :female : nil
			t_pers = @sport.match_periods(event.team.category.rules)
			t_cols = t_pers + (edit ? 3 : 2)
			head   = edit ? [ { kind: :side_cell, value: @sport.term(:match, :home), cols: 2, align: :left } ] : [ { kind: :gap, size: 1 } ]
			t_home = team_name(event, home: event.home?, edit:)
			t_away = team_name(event, home: !event.home?, edit:)
			if new
				fields = [ [] ]
				head   = [ { kind: :gap, size: 2 } ] + head
				t_home = [ { kind: :gap, size: 2 } ] + t_home
				t_away = [ { kind: :gap, size: 2 } ] + t_away
			else
				fields  = [ [ { kind: :gap, size: 1, cols: t_cols, class: "text-xs" } ] ]
				score   = @sport.match_score(event.id)
				periods = @sport.periods
				match_score_fields(event.home?, score, periods, t_pers, head, t_home, t_away, edit:)
				head << topcell(UI::Stat.fld(:total, :short))
				team_period_score(event.home?, :tot, t_home, t_away, score[:tot], edit:)
			end
			fields += [ head, t_home, t_away ]
			unless new
				fields << [ { kind: :gap, size: 1, cols: t_pers + 3, class: "text-xs" } ]
				fields << [ { kind: :side_cell, value: @sport.term(:athlete, :plural, gender:), align: :left, cols: t_cols } ]
			end
			fields
		end

		private
			def s_label(stat, short: true)
				tail = short ? "_short" : ""
				@sport.t_path(:stats, "#{stat}#{tail}".to_sym)
			end

			def topcell(value, cols: nil, rows: nil, align: :center)
				{ kind: :top_cell, cols:, rows:, align:, value: }
			end

			def team_name(event, home:, edit: false)
				if edit
					action = "change->match-location#selectHomeCourt"
					rivals = event.team.rival_teams_info
					if home
						[
							{ kind: :radio_button, key: :home, value: true, checked: event.home, align: :right, data: { action:, match_location_target: "homeRadio" } },
							{ kind: :side_cell, align: :left, value: event.team.to_s }
						]
					else
						[
							{ kind: :radio_button, key: :home, value: false, checked: !event.home, align: :right, data: { action: } },
							{ kind: :text_box, key: :name, value: event.name, placeholder: @sport.term(:rival, :default), options: rivals.keys, size: 12, data: { action:, homecourts: rivals.values, match_location_target: "rivalName" } }
						]
					end
				else
					[ { kind: :side_cell, value: (home ? event.team.to_s : event.name), align: :left } ]
				end
			end

			def team_period_score(home, period, t_home, t_away, val, edit: false)
				p_home = (val ? (home ? val[:ours] : val[:opps]) : 0)
				p_away = (val ? (home ? val[:opps] : val[:ours]) : 0)
				k_tail = "_#{period}_1"
				k_home = "#{(home ? 'ours' : 'opps')}#{k_tail}"
				k_away = "#{(home ? 'opps' : 'ours')}#{k_tail}"
				if edit
					t_home << { kind: :number_box, key: k_home, min: 0, max: 200, size: 1, value: p_home, align: :center }
					t_away << { kind: :number_box, key: k_away, min: 0, max: 200, size: 1, value: p_away, align: :center }
				else
					t_home << { kind: :normal, value: p_home, class: "text-center border px-1 py-1", align: :right }
					t_away << { kind: :normal, value: p_away, class: "text-center border px-1 py-1", align: :right }
				end
			end

			def match_score_fields(home, score, periods, t_pers, head, t_home, t_away, edit: false)
				rsc = { ours: 0, opps: 0 }
				1.upto(t_pers) do |key|
					per = periods.key(key)
					val = score[per]
					if val
						rsc[:ours] += val[:ours]
						rsc[:opps] += val[:opps]
					end
					head << topcell(@sport.t_path(:periods, :values, "#{per}_short".to_sym))
					team_period_score(home, per, t_home, t_away, val, edit:)
				end
				if edit || (rsc[:ours] == rsc[:opps] && rsc[:ours] > 0)
					head << topcell(@sport.t_path(:periods, :values, :ot_short))
					team_period_score(home, :ot, t_home, t_away, score[:ot], edit:)
				end
			end

			def match_stats_header(edit: false)
				fields = [
					{ kind: :normal, value: Assignment.fld(:number, :short), align: :center },
					{ kind: :normal, value: Person.fld(:name) },
					{ kind: :normal, value: "#{s_label(:sec)} (\")", align: :center, hide_mobile: true }
				]
				fields << { kind: :normal, value: s_label(:pts), align: :center } unless edit
				fields += [
					{ kind: :normal, value: s_label(:t2), cols: 3, align: :center, hide_mobile: true },
					{ kind: :normal, value: s_label(:t3), cols: 3, align: :center, hide_mobile: true },
					{ kind: :normal, value: s_label(:ft), cols: 3, align: :center, hide_mobile: true },
					{ kind: :normal, value: s_label(:trb), align: :center },
					{ kind: :normal, value: s_label(:ast), align: :center },
					{ kind: :normal, value: s_label(:stl), align: :center },
					{ kind: :normal, value: s_label(:blk), align: :center },
					{ kind: :normal, value: s_label(:to), align: :center },
					{ kind: :normal, value: s_label(:pfc), align: :center }
				]
			end

			def match_stats_row(athlete, stats, edit: false)
				prefix     = "#{athlete.id}_0_"
				statistics = @sport.statistics

				fields = [
					{ kind: :normal, value: athlete.number, align: :center },
					{ kind: :normal, value: athlete.s_name },
					@sport.stat_field(prefix, stats, statistics.fetch(:sec), edit:, hide_mobile: true)
				]

				fields << @sport.stat_field(prefix, stats, statistics.fetch(:pts), edit:) unless edit

				fields += [
					@sport.stat_field(prefix, stats, statistics.fetch(:t2m), edit:, hide_mobile: true),
					{ kind: :normal, value: "/", hide_mobile: true },
					@sport.stat_field(prefix, stats, statistics.fetch(:t2a), edit:, hide_mobile: true),
					@sport.stat_field(prefix, stats, statistics.fetch(:t3m), edit:, hide_mobile: true),
					{ kind: :normal, value: "/", hide_mobile: true },
					@sport.stat_field(prefix, stats, statistics.fetch(:t3a), edit:, hide_mobile: true),
					@sport.stat_field(prefix, stats, statistics.fetch(:ftm), edit:, hide_mobile: true),
					{ kind: :normal, value: "/", hide_mobile: true },
					@sport.stat_field(prefix, stats, statistics.fetch(:fta), edit:, hide_mobile: true),
					@sport.stat_field(prefix, stats, statistics.fetch(:trb), edit:),
					@sport.stat_field(prefix, stats, statistics.fetch(:ast), edit:),
					@sport.stat_field(prefix, stats, statistics.fetch(:stl), edit:),
					@sport.stat_field(prefix, stats, statistics.fetch(:blk), edit:),
					@sport.stat_field(prefix, stats, statistics.fetch(:to), edit:),
					@sport.stat_field(prefix, stats, statistics.fetch(:pfc), edit:)
				]
			end
	end
end
