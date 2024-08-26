# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
# Manage Basketball rules / stats, etc.
class BasketballSport < Sport
	SPORT_LBL        = "sport.basketball."
	ATTEMPT_CONCEPTS = [:fta, :fga, :tza, :t3a, :t2a, :tma].freeze
	ATTEMPT_KEYVALS  = [3, 5, 9, 7, 11, 13].freeze
	SCORED_CONCEPTS  = [:ftm, :fgm, :tzm, :t3m, :t2m, :tmm].freeze
	SCORED_KEYVALS   = [4, 6, 8, 10, 12, 14].freeze

	# Setup the basic settings
	def initialize(*args)
		super(*args)
		self.name = "basketball"
		self.basketball_rules if self.rules.empty?
		self.basketball_scoring if self.scoring.empty?
		self.basketball_periods if self.periods.empty?
		self.basketball_limits if self.limits.empty?
		self.basketball_stats if self.stats.empty?
	end

	# return parent object
	def generic
		self.becomes(Sport)
	end

	# fields to display match information - not title
	def match_show_fields(event)
		match_fields(event)
	end

	# fields to edit a match
	def match_form_fields(event, new: false)
		match_fields(event, edit: true, new:)
	end

	# return period limitations for a match of this sport
	# depends on rules applied
	def match_outings(a_rules)
		s_limits = self.limits[a_rules.to_s] if self.rules[a_rules]
		p_total  = s_limits["periods"]["regular"]
		if (outings = s_limits["outings"])
			p_first  = s_limits["outings"]["first"]
			p_min    = s_limits["outings"]["min"]
			p_max    = s_limits["outings"]["max"]
			outings = {total: p_total, first: p_first, min: p_min, max: p_max}
		end
		outings
	end

	# grid to show/edit player outings for a match
	def outings_grid(event, outings, edit: false, rdx: nil)
		title = [{kind: "normal", value: I18n.t("player.number"), align: "center"}, {kind: "normal", value: I18n.t("person.name")}]
		rows  = []
		kind  = (edit ? "text" : "normal")
		e_stats    = event.stats
		rules      = self.rules.key(event.team.category.rules)
		data       = self.limits[rules]["outings"]
		data[:tot] = self.limits[rules]["periods"]["regular"]
		data[:act] = self.limits[rules]["playing"]["max"]
		if periods
			q_players = {}
			1.upto(outings[:total]) do |i|
				title << {kind: "normal", value: I18n.t("#{SPORT_LBL}period.q#{i}")}
				q_players[i] = 0
			end
		end
		event.players.order(:number).each do |player|
			p_outings  = 0
			p_stats    = Stat.fetch(player_id: player.id, stats: e_stats, create: false)
			row        = {items: []}
			row[:url]  = "/players/#{player.id}?event_id=#{event.id}&rdx=#{rdx}" unless edit
			row[:items] << {kind:, value: player.number.to_s, align: "center"}
			row[:items] << {kind:, value: player.s_name}
			1.upto(outings[:total]) do |q|
				q_val = Stat.fetch(period: q, stats: p_stats, create: false).first&.value.to_i
				if edit
					row[:items] << {kind: "checkbox-q", key: :outings, player_id: player.id, q: "q#{q}", value: q_val, align: "center", data: {columnId: "q#{q}"}}
				elsif (q_val == 1)
					p_outings    += 1 if (q <= data["first"])
					q_players[q] += 1
					row[:items] << {kind: "icon", value: "Yes.svg", class: ""}
				else
					row[:items] << {kind: "gap", size: 1, class: "border px py"}
				end
			end
			row[:classes] = (p_outings < data["min"]) || (p_outings > data["max"]) ? ["border", "px", "py", "bg-red-300"] : []
			rows << row
		end
		unless edit
			1.upto(outings[:total]) do |i|
				if q_players[i] != data[:act]	# higligh all the Q as "bad"
					rows.each {|row| row[:items][1+i][:class] += " bg-red-300"}
				end
			end
		end
		{title:, rows:, data:}
	end

	# grid to show/edit player stats for a match
	def stats_grid(event, edit: false, rdx: nil)
		head = match_stats_header(edit:)
		rows = []
		e_stats = event.stats
		event.players.each do |player|
			p_stats   = Stat.fetch(player_id: player.id, period: 0, stats: e_stats, create: false)
			row       = {items: []}
			row[:url] = "/players/#{player.id}?event_id=#{event.id}&rdx=#{rdx}" unless edit
			row[:items] = match_stats_row(player, p_stats, edit:)
			rows << row
		end
		{title: head, rows: rows}
	end

	# fields to display player's stats for training
	def player_training_stats_fields(event, player_id:)
		stats = Stat.fetch(event_id: event.id, period: 0, player_id:, create: false)
		res   = player_training_stats_header
		res << show_shooting_data(s_label("ft"), stats, :ftm, :fta)
		res << show_shooting_data(s_label("tz"), stats, :tzm, :tza)
		res << show_shooting_data(s_label("tm"), stats, :tmm, :tma)
		res << show_shooting_data(s_label("t3"), stats, :t3m, :t3a)
		get_shooting_totals(event.id, player_id, stats)
		res << show_shooting_data(I18n.t("stat.total_a"), stats, :fgm, :fga)
		res
	end

	# fields to track player training stats
	def player_training_stats_form_fields(event, player_id:)
		key   = "#{player_id}_0_"
		stats = Stat.fetch(event_id: event.id, player_id:)
		res   = player_training_stats_header
		res << form_shooting_data(key, s_label("ft"), stats, :ftm, :fta)
		res << form_shooting_data(key, s_label("tz"), stats, :tzm, :tza)
		res << form_shooting_data(key, s_label("tm"), stats, :tmm, :tma)
		res << form_shooting_data(key, s_label("t3"), stats, :t3m, :t3a)
		res
	end

	# fields to show rules limits
	def rules_limits_fields
		res    = rules_limits_title_fields
		rules  = self.rules
		limits = self.limits
		rules.each_key do |rule|
			res << rules_limits_row_fields(rule, limits[rule])
		end
		res
	end

	# default applicable rules for a category
	def default_rules(category)
		case category.max_years
		when 13	then return 1	# U14
		when 11	then return 2	# U12
		when 9	then return 3	# U10
		when 7	then return 4	# U8
		else return 0	# fiba (0) or 3x3 (6)
		end
	end

	# return rules that may apply to BASKETBALL:
	def rules_options
		[
			[I18n.t("#{SPORT_LBL}rules.fiba"), 0],
			[I18n.t("#{SPORT_LBL}rules.u14"), 1],
			[I18n.t("#{SPORT_LBL}rules.u12"), 2],
			[I18n.t("#{SPORT_LBL}rules.u10"), 3],
			[I18n.t("#{SPORT_LBL}rules.u8"), 4],
			[I18n.t("#{SPORT_LBL}rules.three"), 5]
		]
	end

	# Some pre-processing of stats_data
	# before parsing normally - grouping & additional calculations
	def parse_stats(event, stats_data)
		event.players.each { |player| parse_player_stats(player.id, stats_data) }
		return super(event, stats_data)
	end

	private
		# generic creation of stats if inexistent in database
		def basketball_stats
			self.stats = {
				sec: 0, # seconds played/trained
				pts: 1, # points
				pta: 2,	# total points shot
				fta: 3, # Free Throws
				ftm: 4,
				fga: 5,	# field goals
				fgm: 6,
				t2a: 7, # Two point shots
				t2m: 8,
				tza: 9,	# shots near basket
				tzm: 10,
				tma: 11, # mid-range shots
				tmm: 12,
				t3a: 13, # Three point shots
				t3m: 14,
				drb: 15, # defensive rebounds
				orb: 16, # offensive rebounds
				trb: 17,
				ast: 18,  # assists
				stl: 19,  # steals
				to: 20, # turnovers
				blk: 21,  # blocks
				bla: 22,  # blocks against
				pfc: 23,  # fouls committed
				pfr: 24,  # fouls received
				q1: 25, # outing in each quarter
				q2: 26,
				q3: 27,
				q4: 28,
				q5: 29,
				q6: 30,
				ot: 31
			}
		end

		# category rulesets
		def basketball_rules
			self.rules = {fiba: 0, u14: 1, u12: 2, u10: 3, u8: 4, three: 5}
		end

		# set default limits applicable to rules
		# {rules(int): {roster: {max:, min:}, playing: {max:, min:}, periods: {regular:, extra:}, outings: {first:, max:, min:}, duration: {regular:, extra:}}}
		def basketball_limits
			limits = {}
			limits[:fiba]  = {roster: {max: 16, min: 5}, playing: {max: 5, min: 2}, periods: {regular: 4, extra: 10}, duration: {regular: 600, extra: 300}}
			limits[:u14]   = {roster: {max: 16, min: 5}, playing: {max: 5, min: 2}, outings: {first: 3, max: 2, min: 1}, periods: {regular: 4, extra: 10}, duration: {regular: 600, extra: 300}}
			limits[:u12]   = {roster: {max: 16, min: 5}, playing: {max: 5, min: 2}, outings: {first: 5, max: 3, min: 2}, periods: {regular: 6, extra: 10}, duration: {regular: 480, extra: 300}}
			limits[:u10]   = {roster: {max: 16, min: 5}, playing: {max: 5, min: 2}, outings: {first: 3, max: 2, min: 1}, periods: {regular: 4, extra: 10}, duration: {regular: 600, extra: 300}}
			limits[:u8]    = {roster: {max: 16, min: 5}, playing: {max: 4, min: 2}, outings: {first: 3, max: 2, min: 1}, periods: {regular: 4, extra: 10}, duration: {regular: 480, extra: 300}}
			limits[:three] = {roster: {max: 5, min: 3}, playing: {max: 3, min: 2}, periods: {regular: 1, extra: 10}, duration: {regular: 420, extra: 180}}
			self.limits = limits
		end

		# generic periods definition
		def basketball_periods
			self.periods = {tot: 0, q1: 1, q2: 2, q3: 3, q4: 4, q5: 5, q6: 6, ot: 7}
		end

		# generic setting method to be used for all setters
		def basketball_scoring
			self.scoring = {sets: false, points: :pts}
		end

		# header fields to show player training_stats
		def player_training_stats_header
			res = [[{kind: "gap"}, {kind: "side-cell", value: I18n.t("stat.many"), align: "middle", cols: 5}]]
			res << [
				{kind: "gap"},
				{kind: "top-cell", value: I18n.t("#{SPORT_LBL}shot.many")},
				{kind: "top-cell", value: I18n.t("#{SPORT_LBL}shot.scored"), align: "middle"},
				{kind: "top-cell", value: "/", align: "middle"},
				{kind: "top-cell", value: I18n.t("#{SPORT_LBL}shot.attempt"), align: "middle"}
			]
		end

		# return label for a Baskeball stat
		def s_label(label, abbr: true)
			tail = abbr ? ".abbr" : ".many"
			I18n.t("#{SPORT_LBL}stat.#{label}#{tail}")
		end

		# standardised shooting data fields
		def show_shooting_data(label, stats, scored, attempts)
			s_key = self.stats[scored.to_s]
			a_key = self.stats[attempts.to_s]
			made  = Stat.fetch(concept: s_key, period: 0, stats:).first&.value.to_i
			taken = Stat.fetch(concept: a_key, period: 0, stats:).first&.value.to_i
			pctg  = taken > 0 ? (made*100/taken) : "N/A"
			pcol  = taken == 0 ? "gray-300" : (pctg < 20 ? "red-900": (pctg < 50 ? "yellow-700" : (pctg < 70 ? "gray-700" : "green-700")))
			[
				{kind: "gap"},
				stat_label_field(label),
				{kind: "string", value: made, class: "border px py", align: "right"},
				{kind: "label", value: "/"},
				{kind: "string", value: taken, class: "border px py", align: "right"},
				{kind: "text", value: (taken == 0 ? pctg : "#{pctg}%"), class: "align-middle text-#{pcol}", align: "center"}
			]
		end

		# add field goal totals to shooting_data stats
		def get_shooting_totals(event_id, player_id, stats)
			made = include_stat_in_event(event_id:, player_id:, period: 0, concept: :fgm)
			made.update(value: sum_stats(stats, SCORED_KEYVALS))
			shot = include_stat_in_event(event_id:, player_id:, period: 0, concept: :fga)
			shot.update(value: sum_stats(stats, ATTEMPT_KEYVALS))
		end

		# standardised shooting form fields
		def form_shooting_data(key, label, stats, scored, attempts)
			k_made  = self.stats[scored.to_s]
			v_made  = Stat.fetch(concept: k_made, stats:).first&.value.to_i
			k_taken = self.stats[attempts.to_s]
			v_taken = Stat.fetch(concept: k_taken, stats:).first&.value.to_i
			[
				{kind: "gap"},
				stat_label_field(label),
				{kind: "number-box", key: "#{key}#{k_made}", value: v_made, class: "shots-made border px py", align: "right"},
				{kind: "label", value: "/"},
				{kind: "number-box", key: "#{key}#{k_taken}", value: v_taken, class: "shots-taken border px py", align: "right"}
			]
		end

		# fields to show the sport rules limits title
		def rules_limits_title_fields
			[
				[
					{kind: "top-cell", value: I18n.t("sport.rules"), rows: 3},
					{kind: "top-cell", value: I18n.t("sport.period.many"), align: "center", cols: 4},
					{kind: "top-cell", value: I18n.t("team.roster"), align: "center", cols: 2, rows: 2},
					{kind: "top-cell", value: I18n.t("#{SPORT_LBL}outings.playing"), align: "center", cols: 2, rows: 2},
					{kind: "top-cell", value: I18n.t("#{SPORT_LBL}outings.quarter"), align: "center", cols: 3, rows: 2},
				],
				[
					{kind: "top-cell", value: I18n.t("sport.period.regular"), align: "center", cols: 2},	# periods
					{kind: "top-cell", value: I18n.t("sport.period.extra"), align: "center", cols: 2}
				],
				[
					{kind: "top-cell", value: I18n.t("sport.period.qty")},	# regular
					{kind: "top-cell", value: I18n.t("sport.period.duration")},
					{kind: "top-cell", value: I18n.t("sport.period.qty")},	# extra
					{kind: "top-cell", value: I18n.t("sport.period.duration")},
					{kind: "top-cell", value: I18n.t("stat.max")},	# match roster
					{kind: "top-cell", value: I18n.t("stat.min")},
					{kind: "top-cell", value: I18n.t("stat.max")},	# match playing
					{kind: "top-cell", value: I18n.t("stat.min")},
					{kind: "top-cell", value: I18n.t("#{SPORT_LBL}outings.first")},	# outings
					{kind: "top-cell", value: I18n.t("stat.max")},	# in field
					{kind: "top-cell", value: I18n.t("stat.min")}
				]
			]
		end

		# fields for a row of rules limits
		def rules_limits_row_fields(rule, limit)
			g_cls  = "border"
			n_cls  = "#{g_cls} text-center"
			r_per  = limit["periods"]
			r_dur  = limit["duration"]
			r_ros  = limit["roster"]
			r_play = limit["playing"]
			r_out  = limit["outings"] ? limit["outings"] : {"first" => "N/A", "min" => "N/A", "max" => "N/A"}
			[
				{kind: "normal", value: I18n.t("#{SPORT_LBL}rules.#{rule}"), class: g_cls},
				{kind: "normal", value: r_per["regular"], class: n_cls},
				{kind: "normal", value: r_dur["regular"]/60, class: n_cls},
				{kind: "normal", value: r_per["extra"], class: n_cls},
				{kind: "normal", value: r_dur["extra"]/60, class: n_cls},
				{kind: "normal", value: r_ros["max"], class: n_cls},
				{kind: "normal", value: r_ros["min"], class: n_cls},
				{kind: "normal", value: r_play["max"], class: n_cls},
				{kind: "normal", value: r_play["min"], class: n_cls},
				{kind: "normal", value: r_out["first"], class: n_cls},
				{kind: "normal", value: r_out["max"], class: n_cls},
				{kind: "normal", value: r_out["min"], class: n_cls}
			]
		end

		# generic match_fields generator for show or edit
		def match_fields(event, edit: false, new: false)
			t_pers  = self.match_periods(event.team.category.rules)
			t_cols  = t_pers + (edit ? 3 : 2)
			head    = edit ? [{kind: "side-cell", value: I18n.t("team.home_a"), cols: 2, align: "left"}] : [{kind: "gap", size:1}]
			t_home  = team_name_fields(event, home: event.home?, edit:)
			t_away  = team_name_fields(event, home: !event.home?, edit:)
			if new
				fields = [[]]
				head   = [{kind: "gap", size: 2}] + head
				t_home = [{kind: "gap", size: 2}] + t_home
				t_away = [{kind: "gap", size: 2}] + t_away
			else	# editing an existing match - more fields to show
				fields  = [[{kind: "gap", size: 1, cols: t_cols, class: "text-xs"}]]
				score   = self.match_score(event.id)
				periods = self.periods
				match_score_fields(event.home?, score, periods, t_pers, head, t_home, t_away, edit:)
				head << {kind: "top-cell", value: I18n.t("stat.total_a"), align: "center"}
				team_period_score_fields(event.home?, :tot, t_home, t_away, score[:tot], edit:)
			end
			fields += [head, t_home, t_away]
			unless new
				fields << [{kind: "gap", size: 1, cols: t_pers + 3, class: "text-xs"}]
				fields << [{kind: "side-cell", value: I18n.t("player.many"), align:"left", cols: t_cols}]
			end
			fields
		end

		# fields for home team in a match
		def team_name_fields(event, home:, edit: false)
			if edit
				action = "change->match-location#selectHomeCourt"
				rivals = event.team.rival_teams_info
				if home
					[
						{kind: "radio-button", key: :home, value: true, checked: event.home, align: "right", r_data: {action:, match_location_target: "homeRadio"}},
						{kind: "side-cell", align: "left", value: event.team.to_s}
					]
				else
					[
						{kind: "radio-button", key: :home, value: false, checked: !event.home, align: "right", r_data: {action:}},
						{kind: "text-box", key: :name, value: event.name, placeholder: I18n.t("match.default_rival"), options: rivals.keys, size: 12, o_data: {action:, homecourts: rivals.values, match_location_target: "rivalName"}}
					]
				end
			else	# show
				[{kind: "side-cell", value: (home ? event.team.to_s : event.name), align: "left"}]
			end
		end

		# add fields to team period scores
		def team_period_score_fields(home, period, t_home, t_away, val, edit: false)
			p_home = (val ? (home ? val[:ours] : val[:opps]) : 0)
			p_away = (val ? (home ? val[:opps] : val[:ours]) : 0)
			k_tail = "_#{period}_1"
			k_home = "#{(home ? 'ours' : 'opps')}#{k_tail}"
			k_away = "#{(home ? 'opps' : 'ours')}#{k_tail}"
			if edit
				t_home << {kind: "number-box", key: k_home, min: 0, max: 200, size: 2, value: p_home, align: "center"}
				t_away << {kind: "number-box", key: k_away, min: 0, max: 200, size: 2, value: p_away, align: "center"}
			else
				t_home << {kind: "normal", value: p_home, class: "text-center border px py", align: "right"}
				t_away << {kind: "normal", value: p_away, class: "text-center border px py", align: "right"}
			end
		end

		# fill head, t_home & t_away the fields for match score
		def match_score_fields(home, score, periods, t_pers, head, t_home, t_away, edit: false)
			rsc = {ours: 0, opps: 0} # may not need to show overtime scores
			1.upto(t_pers) do |key|
				per = periods.key(key)
				val = score[key]
				if val
					rsc[:ours] += val[:ours]
					rsc[:opps] += val[:opps]
				end
				head << {kind: "top-cell", value: I18n.t("#{SPORT_LBL}period.#{per}"), align: "center"}
				team_period_score_fields(home, per, t_home, t_away, val, edit:)
			end
			if edit || (rsc[:ours] == rsc[:opps] && rsc[:ours] > 0)
				head << {kind: "top-cell", value: I18n.t("#{SPORT_LBL}period.ot"), align: "center"}
				team_period_score_fields(home, :ot, t_home, t_away, score[:ot], edit:)
			end
	end

		# return fields for stats view
		def match_stats_header(edit: false)
			fields = [
				{kind: "normal", value: I18n.t("player.number"), align: "center"},
				{kind: "normal", value: I18n.t("person.name")},
				{kind: "normal", value: s_label(:sec), align: "center"}
			]
			fields <<	{kind: "normal", value: s_label(:pts), align: "center"} unless edit
			fields += [
				{kind: "normal", value: s_label(:ft), cols: 3, align: "center"},
				{kind: "normal", value: s_label(:t2), cols: 3, align: "center"},
				{kind: "normal", value: s_label(:t3), cols: 3, align: "center"},
				{kind: "normal", value: s_label(:trb), align: "center"},
				{kind: "normal", value: s_label(:ast), align: "center"},
				{kind: "normal", value: s_label(:stl), align: "center"},
				{kind: "normal", value: s_label(:blk), align: "center"},
				{kind: "normal", value: s_label(:to), align: "center"},
				{kind: "normal", value: s_label(:pfc), align: "center"}
			]
		end

		# row fields for a player's stats
		def match_stats_row(player, stats, edit: false)
			key  = "#{player.id}_0_"
			secs = Stat.fetch(concept: 0, stats:, create: false).first&.value.to_i
			if edit
				tbox = {kind: "number-box", key: "#{key}0", max: 5400, min: 0, size: 3, value: secs, units: "\""}
			else
				tbox = {kind: "normal", value: self.time_string(secs), align: "right"}
			end
			fields = [
				{kind: "normal", value: player.number, align: "center"},
				{kind: "normal", value: player.s_name},
				tbox
			]
			#show points only when not editing
			fields <<	match_stats_field(key, stats, 2, edit:) unless edit
			fields +=	[
				match_stats_field(key, stats, 4, edit:),	# ftm
				{kind: "normal", value: "/"},
				match_stats_field(key, stats, 3, edit:),	# fta
				match_stats_field(key, stats, 8, edit:),	# t2a
				{kind: "normal", value: "/"},
				match_stats_field(key, stats, 7, edit:),	# t2m
				match_stats_field(key, stats, 14, edit:),	# t3a
				{kind: "normal", value: "/"},
				match_stats_field(key, stats, 13, edit:),	# t3m
				match_stats_field(key, stats, 17, edit:),	# trb
				match_stats_field(key, stats, 18, edit:),	# ast
				match_stats_field(key, stats, 19, edit:),	# stl
				match_stats_field(key, stats, 21, edit:),	# blk
				match_stats_field(key, stats, 20, edit:),	# to
				match_stats_field(key, stats, 23, edit:),	# fouls
			]
		end

		# return a match_stats field for edit/view
		def match_stats_field(key, stats, concept, edit: false)
			key   = "#{key}#{concept}"
			value = Stat.fetch(concept:, stats:, create: false).first&.value.to_i
			if edit
				{kind: "number-box", key:, value:, class: "hover:text-blue-900"}
			else
				{kind: "normal", value:, align: "right"}
			end
		end

		# parse a player's stats from a form input
		def parse_player_stats(player_id, stats)
			kplay = "#{player_id}_0_"
			pstat = {pta: 0, pts: 0, fga: 0, fgm: 0, t2a: 0, t2m: 0}
			stats.each_pair do |key, val|
				if key.start_with?(kplay)
					keyarg = key.split("_")
					kplay  = "#{keyarg[0]}_#{keyarg[1]}_"
					kval   = val.to_i
					case keyarg[2].to_i # deal with concepts
					when 3; pstat[:pta] += kval	# free throws
					when 4; pstat[:pts] += kval
					# 5 & 6 total field goals - calculated
					# we'll get either 7 & 8 or 9..12
					when 7;	pstat[:fga] += kval; pstat[:t2a] += kval; pstat[:pta] += (2 * kval)	# Total 2P shots
					when 8;	pstat[:fgm] += kval; pstat[:t2m] += kval; pstat[:pts] += (2 * kval)
					when 9;	pstat[:fga] += kval; pstat[:t2a] += kval; pstat[:pta] += (2 * kval)	# near basket
					when 10; pstat[:fgm] += kval; pstat[:t2m] += kval; pstat[:pts] += (2 * kval)
					when 11; pstat[:fga] += kval; pstat[:t2a] += kval; pstat[:pta] += (2 * kval)	# mid range
					when 12; pstat[:fgm] += kval; pstat[:t2m] += kval; pstat[:pts] += (2 * kval)
					when 13; pstat[:fga] += kval; pstat[:pta] += (3 * kval)	# 3 pointers
					when 14; pstat[:fgm] += kval; pstat[:pts] += (3 * kval)
					end
				end
			end
			stats["#{kplay}1"] = pstat[:pta]
			stats["#{kplay}2"] = pstat[:pts]
			stats["#{kplay}5"] = pstat[:fga]
			stats["#{kplay}6"] = pstat[:fgm]
			stats["#{kplay}7"] = pstat[:t2a]
			stats["#{kplay}8"] = pstat[:t2m]
		end
end
