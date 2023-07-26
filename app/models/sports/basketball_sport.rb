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
# Manage Basketball rules / stats, etc.
class BasketballSport < Sport
	SPORT_LBL        = "sport.basketball."
	ATTEMPT_CONCEPTS = [:zga, :tga, :dga, :fta].freeze
	ATTEMPT_KEYVALS  = [4, 8, 6, 10].freeze
  SCORED_CONCEPTS  = [:zgm, :tgm, :dgm, :ftm].freeze
  SCORED_KEYVALS   = [5, 9, 7, 11].freeze

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

	def generic
		self.becomes(Sport)
	end

	# fields to display match period
	def match_show_fields(event)
		match_fields(event)
	end

	# fields to display match period
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

	# grid to show basketball period form for an event
	def outings_grid(event, outings, edit: false)
		head = [{kind: "top-cell", value: I18n.t("player.number"), align: "center"}, {kind: "top-cell", value: I18n.t("person.name")}]
		rows = []
		e_stats = event.stats
		1.upto(outings[:total]) {|i| head << {kind: "normal", value: I18n.t("#{SPORT_LBL}period.q#{i}")}} if periods
		event.players.order(:number).each do |player|
			p_stats = Stat.by_player(player.id, e_stats)
			row     = {url: "/players/#{player.id}?retlnk=/events/#{event.id}#{(edit ? '/edit' : '')}", items: []}
			row[:items] << {kind: "normal", value: player.number, align: "center"}
			row[:items] << {kind: "normal", value: player.to_s}
			1.upto(outings[:total]) do |q|
				q_stat = Stat.by_q(q, p_stats).first
				if edit
					row[:items] << {kind: "checkbox-q", key: :stats, player_id: player.id, q: "q#{q}", value: q_stat ? q_stat[:value] : 0, align: "center"}
				else
					row[:items] << ((q_stat and q_stat[:value]==1) ? {kind: "icon", value: "Yes.svg"} : {kind: "gap", size: 1, class: "border px py"})
				end
			end
			rows << row
		end
		{title: head, rows: rows}
	end

	# grid to show basketball stats for a match
	def stats_grid(event, edit: false)
		head = match_stats_header
		rows = []
		e_stats = event.stats
		event.players.each do |player|
			p_stats = Stat.fetch(player_id: player.id, period: 0, stats: e_stats, create: false)
			row     = {url: "/players/#{player.id}?retlnk=/events/#{event.id}#{(edit ? '/edit' : '')}", items: []}
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
		res << show_shooting_data(s_label("zg"), stats, :zgm, :zga)
		res << show_shooting_data(s_label("dg"), stats, :dgm, :dga)
		res << show_shooting_data(s_label("tg"), stats, :tgm, :tga)
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
		res << form_shooting_data(key, s_label("zg"), stats, :zgm, :zga)
		res << form_shooting_data(key, s_label("dg"), stats, :dgm, :dga)
		res << form_shooting_data(key, s_label("tg"), stats, :tgm, :tga)
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

	# return an I18n string for a category
	def rules_name(rules)
		I18n.t("#{SPORT_LBL}rules.#{rules}")
	end

	# Return which limits apply depending on the rules
	def rules_limits(category_rules)
		self.limits[category_rules]
	end

	private
		# generic creation of stats if inexistent in database
		def basketball_stats
			self.stats = {
				sec: 0, # seconds played/trained
				pts: 1, # points
				fga: 2,	# field goals
				fgm: 3,
				zga: 4,	# shots near basket
				zgm: 5,
				dga: 6, # #two point shots
				dgm: 7,
				tga: 8, # Three point shots
				tgm: 9,
				fta: 10, # Free Throws
				ftm: 11,
				drb: 12, # defensive rebounds
				orb: 13, # offensive rebounds
				trb: 14,
				ast: 15,  # assists
				stl: 16,  # steals
				to: 17, # turnovers
				blk: 18,  # blocks
				bla: 19,  # blocks against
				pfc: 20,  # fouls committed
				pfr: 21,  # fouls received
				q1: 22, # outing in each quarter
				q2: 23,
				q3: 34,
				q4: 25,
				q5: 26,
				q6: 27,
				ot: 28,
				psa: 29	# total points shot
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
			made  = Stat.fetch(concept: s_key, stats:).first&.value.to_i
			taken = Stat.fetch(concept: a_key, stats:).first&.value.to_i
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
			made = include_stat_in_event(event_id:, player_id:, period: 0, concept: :fgm, stats:)
			made.update(value: sum_stats(stats, SCORED_KEYVALS))
			shot = include_stat_in_event(event_id:, player_id:, period: 0, concept: :fga, stats:)
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
				if home
					[
						{kind: "radio-button", key: :home, value: true, checked: event.home, align: "right"},
						{kind: "side-cell", align: "left", value: event.team.to_s}
					]
				else
					[
						{kind: "radio-button", key: :home, value: false, checked: !event.home, align: "right"},
						{kind: "text-box", key: :name, value: event.name, placeholder: I18n.t("match.default_rival"), size: 12}
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
			1.upto(t_pers) do |key|
				per = periods.key(key)
				val = score[key]
				head << {kind: "top-cell", value: I18n.t("#{SPORT_LBL}period.#{per}"), align: "center"}
				team_period_score_fields(home, per, t_home, t_away, val, edit:)
			end
			head << {kind: "top-cell", value: I18n.t("#{SPORT_LBL}period.ot"), align: "center"}
			team_period_score_fields(home, :ot, t_home, t_away, score[:ot], edit:)
	end

		# return fields for stats view
		def match_stats_header(edit: false)
			fields = [
					{kind: "normal", value: I18n.t("player.number"), align: "center"},
					{kind: "normal", value: I18n.t("person.name")},
					{kind: "normal", value: s_label(:sec), align: "center"},
					{kind: "normal", value: s_label(:pts), align: "center"},
=begin
					{kind: "normal", value: s_label(:ft), cols: 3, align: "center"},
					{kind: "normal", value: s_label(:dg), cols: 3, align: "center"},
					{kind: "normal", value: s_label(:tg), cols: 3, align: "center"},
=end
					{kind: "normal", value: s_label(:trb), align: "center"},
					{kind: "normal", value: s_label(:ast), align: "center"},
					{kind: "normal", value: s_label(:stl), align: "center"},
					{kind: "normal", value: s_label(:blk), align: "center"},
					{kind: "normal", value: s_label(:to), align: "center"},
					{kind: "normal", value: s_label(:pfc), align: "center"},
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
			[
				{kind: "normal", value: player.number, align: "center"},
				{kind: "normal", value: player.to_s},
				tbox,
				match_stats_field(key, stats, 1, edit:),	# points
=begin
				match_stats_field(stats, 10, edit:),	# ftm
				{kind: "normal", value: "/"},
				match_stats_field(stats, 11, edit:),	# fta
				match_stats_field(stats, 6, edit:),	# dga
				{kind: "normal", value: "/"},
				match_stats_field(stats, 7, edit:),	# dgm
				match_stats_field(stats, 8, edit:),	# tgm
				{kind: "normal", value: "/"},
				match_stats_field(stats, 9, edit:),	# tga
=end
				match_stats_field(key, stats, 14, edit:),	# trb
				match_stats_field(key, stats, 15, edit:),	# ast
				match_stats_field(key, stats, 16, edit:),	# stl
				match_stats_field(key, stats, 18, edit:),	# blk
				match_stats_field(key, stats, 17, edit:),	# to
				match_stats_field(key, stats, 20, edit:),	# fouls
			]
		end

		def match_stats_field(key, stats, concept, edit: false)
			key   = "#{key}#{concept}"
			value = Stat.fetch(concept:, stats:, create: false).first&.value.to_i
			if edit
				{kind: "number-box", key:, value:, class: "hover:text-blue-900"}
			else
				{kind: "normal", value:, align: "right"}
			end
		end
end
