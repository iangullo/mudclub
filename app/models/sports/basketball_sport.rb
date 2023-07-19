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
		self.basketball_periods if self.periods.empty?
		self.basketball_stats if self.stats.empty?
		self.basketball_scoring if self.scoring.empty?
	end

	# fields to display match period
	def match_show_fields(event, edit: nil)
		raise "Must implement in Specific Sport object"
	end

	# fields to display match period
	def match_form_fields(event, edit: nil)
		raise "Must implement in Specific Sport object"
	end

	# fields to display player's stats for training
	def player_training_stats_fields(event_id:, player_id:)
		# filter for this event & player
		stats = Stat.fetch(event_id:, player_id:, create: false)
		res   = shooting_header_fields
		res << show_shooting_data(s_label("ft"), stats, :ftm, :fta)
		res << show_shooting_data(s_label("zg"), stats, :zgm, :zga)
		res << show_shooting_data(s_label("dg"), stats, :dgm, :dga)
		res << show_shooting_data(s_label("tg"), stats, :tgm, :tga)
		get_shooting_totals(event_id, player_id, stats)
		res << show_shooting_data("stat.total_a", stats, :fgm, :fga)
		res
	end

	# fields to track player training stats
	def player_training_stats_form_fields(event_id:, player_id:)
		stats = Stat.fetch(event_id:, player_id:)
		res   = shooting_header_fields
		res << form_shooting_data(s_label("ft"), stats, :ftm, :fta)
		res << form_shooting_data(s_label("zg"), stats, :zgm, :zga)
		res << form_shooting_data(s_label("dg"), stats, :dgm, :dga)
		res << form_shooting_data(s_label("tg"), stats, :tgm, :tga)
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

		# generic periods definition
		def basketball_periods
			self.periods = {tot: 0, q1: 1, q2: 2, q3: 3, q4: 4, ot: 5}
		end

		# generic setting method to be used for all setters
		def basketball_scoring
			self.scoring = {sets: false, points: :pts}
		end

		# header fields to show shooting_stats
		def shooting_header_fields
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
			"#{SPORT_LBL}stat.#{label}#{tail}"
		end

		# standardised shooting data fields
		def show_shooting_data(label, stats, scored, attempts)
			s_key = self.stats[scored.to_s]
			a_key = self.stats[attempts.to_s]
			made  = Stat.by_concept(s_key, stats).first&.value.to_i
			taken = Stat.by_concept(a_key, stats).first&.value.to_i
			pctg  = taken > 0 ? (made*100/taken) : "N/A"
			pcol  = taken == 0 ? "gray-300" : (pctg < 20 ? "red-900": (pctg < 50 ? "yellow-700" : (pctg < 70 ? "gray-700" : "green-700")))
			[
				{kind: "gap"},
				stat_label(label),
				{kind: "string", value: made, class: "border px py", align: "right"},
				{kind: "label", value: "/"},
				{kind: "string", value: taken, class: "border px py", align: "right"},
				{kind: "text", value: (taken == 0 ? pctg : "#{pctg}%"), class: "align-middle text-#{pcol}", align: "center"}
			]
		end

		# add field goal totals to shooting_data stats
		def get_shooting_totals(event_id, player_id, stats)
			made = include_stat_in_event(event_id:, player_id:, concept: :fgm, stats:)
			made.update(value: sum_stats(stats, SCORED_KEYVALS))
			shot = include_stat_in_event(event_id:, player_id:, concept: :fga, stats:)
			shot.update(value: sum_stats(stats, ATTEMPT_KEYVALS))
		end

		# standardised shooting form fields
		def form_shooting_data(label, stats, scored, attempts)
			made  = Stat.by_concept(self.stats[scored.to_s], stats).first&.value.to_i
			taken = Stat.by_concept(self.stats[attempts.to_s], stats).first&.value.to_i
			[
				{kind: "gap"},
				stat_label(label),
				{kind: "number-box", key: scored, value: made, class: "shots-made border px py", align: "right"},
				{kind: "label", value: "/"},
				{kind: "number-box", key: attempts, value: taken, class: "shots-taken border px py", align: "right"}
			]
		end

		# fields to track player training stats
		# REDESIGN!!
		def period_grid(event, edit: nil)
			head = [{kind: "normal", value: I18n.t("player.number"), align: "center"}, {kind: "normal", value: I18n.t("person.name")}]
			rows    = []
			e_stats = event.stats
			1.upto(periods[:total]) {|i| head << {kind: "normal", value: "Q#{i.to_s}"}} if periods
			event.players.order(:number).each do |player|
				p_stats = Stat.by_player(player.id, e_stats)
				row     = {url: "#", frame: "modal", items: []}
				row[:items] << {kind: "normal", value: player.number, align: "center"}
				row[:items] << {kind: "normal", value: player.to_s}
				if periods
					1.upto(periods[:total]) { |q|
						q_stat = Stat.by_q(q, p_stats).first
						if edit
							row[:items] << {kind: "checkbox-q", key: :stats, player_id: player.id, q: "q#{q}", value: q_stat ? q_stat[:value] : 0, align: "center"}
						else
							row[:items] << ((q_stat and q_stat[:value]==1) ? {kind: "icon", value: "Yes.svg"} : {kind: "gap", size: 1, class: "border px py"})
						end
					}
				end
				rows << row
			end
			{title: head, rows: rows}
		end
end
