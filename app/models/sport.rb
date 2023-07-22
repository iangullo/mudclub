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
#
# simple class to have configurable Sports linked to the Club
class Sport < ApplicationRecord
	has_many :categories, dependent: :nullify
	has_many :divisions, dependent: :nullify
	has_many :teams, dependent: :nullify

	# empty wrappers to define FieldComponents for views
	# MUST BE DEFINED IN SPORT-SPECIFIC OBJECTS!!
	def match_show_fields(event, edit: nil)
		raise "Must implement in Specific Sport object"
	end

	def match_form_fields(event, edit: nil)
		raise "Must implement in Specific Sport object"
	end

	def player_training_header_fields(event_id:, player_id:)
		raise "Must implement in Specific Sport object"
	end

	def player_training_stats_fields(event_id:, player_id:)
		raise "Must implement in Specific Sport object"
	end

	def player_training_stats_form_fields(event_id:, player_id:)
		raise "Must implement in Specific Sport object"
	end

	def rules_limits_fields
		raise "Must implement in Specific Sport object"
	end

	def default_rules(category)
		raise "Must implement in Specific Sport object"
	end

	def rules_options
		raise "Must implement in Specific Sport object"
	end

	def rules_name
		raise "Must implement in Specific Sport object"
	end

	def rules_limits
		raise "Must implement in Specific Sport object"
	end

	# multi-language string for sport name
	def to_s
		I18n.t("sport.#{self.name.downcase}.name")
	end

	# retrieve the adequate sport-specific object
	def specific
		obj_cname = self.name.camelize + "Sport"
		obj_class = obj_cname.constantize
		obj_class.new(id: self.id)
	end

	# Getter method for accessing the settings hash
	def settings
		super&.symbolize_keys || {}
	end

	# Setter method for updating the settings hash
	def settings=(value)
		super(value&.to_h)
	end

	# Getter method for accessing the Sport rules mapping
	# as key=>value pairs (enum-like)
	def rules
		settings&.fetch(:rules, {})
	end

	# Setter method for updating the rules mapping
	# as key=>value pairs (enum-like)
	def rules=(value)
		set_setting(:rules, value)
	end

	# Getter method for accessing the Sport limits for matches
	# will vary with sport and categories
	# if any of them are nil, they will be ignored
	# {rules(int): {roster: {max:, min:}, playing: {max:, min:}, periods: {regular:, extra:}, outings: {first:, max:, min:}, duration: {regular:, extra:}}}
	def limits
		settings&.fetch(:limits, {})
	end

	# Setter method for updating the scoring mapping
	# {rules(int): {roster: {max:, min:}, playing: {max:, min:}, periods: {regular:, extra:}, outings: {first:, max:, min:}, duration: {regular:, extra:}}}
	def limits=(value)
		set_setting(:limits, value)
	end

	# Getter method for accessing the Sport scoring. Should
	# identify specific Stats concepts to calculate scoring
	# if any of them are nil, they will be ignored
	# value = {sets: true/false, points: :points_concept}
	def scoring
		settings&.fetch(:scoring, {})
	end

	# Setter method for updating the scoring mapping
	# value = {sets: true/false, points: :points_concept}
	def scoring=(value)
		set_setting(:scoring, value)
	end

	# Getter method for accessing the stat mapping
	# as key=>value pairs
	def stats
		settings&.fetch(:stats, {})
	end

	# Setter method for updating the stat mapping
	# as key=>value pairs
	def stats=(value)
		set_setting(:stats, value)
	end

	# are competition fixtures split in periods?
	# as concept=>value pairs (enum-like)
	def periods
		settings&.fetch(:periods, {})
	end

	# Setter method for updating the periods mapping
	# as concept=>value pairs (enum-like)
	def periods=(value)
		set_setting(:periods, value)
	end

	# returns the score of a match (object of Event class)
	# our team always first - to be tweaked in controllers
	def match_score(event_id:)
		s_stats  = get_event_scoring_stats(event_id:)
		t_score  = {ours: 0, opps: 0}	# (period: 0 => t_score)
		score    = {}
		unless s_stats&.empty?
			r_tot = false
			self.periods.each_pair do |per, val|	#period==set if scoring by sets
				binding.break
				r_tot = read_score(val, s_stats, score, t_score)
			end
		end
		score[:tot] = t_score unless r_tot	# add total unless read
		score
	end

	# wrapper to write match scores. values are expected to
	# be in the form of an array of {period:, p_for:, p_opp:} hashes
	def set_match_score(event_id:, values:)
		s_stats = get_event_scoring_stats(event_id:)	# read them, in case they exist
		values.each do |score|
			r_tot   = (per.to_sym == :tot)
			period  = score[:period]
			s_per   = Stat.by_period(period:, stats: s_stats)
			set_period_score(event_id:, period:, player_id: 0, stats: s_per, value: score[:p_for])
			set_period_score(event_id:, period:, player_id: -1, stats: s_per, value: score[:p_for])
		end
	end

	# return label field for a stat using I18n.t
	def stat_label(label, abbr=true)
		{kind: "side-cell", value: I18n.t(label), align: "middle", class: "border px py"}
	end

	# generic warpper to update a stat value
	def update_stat(event_id:, period:, player_id:, concept:, stats: nil)
		s_val = Stat.fetch(event_id:, period:, player_id:, concept:, stats:).first
		s_val[:value] = value
		s_val.save
		Event.find(event_id).events << s_val unless s_val.id	# add to event stats if needed
	end

	# sum total value of a specific stat
	# if concept included in stat_group array
	def sum_stats(stats, stat_group)
		res = 0
		stats.each do |stat|
			res += stat.value if stat_group.include?(stat.concept)
		end
		res
	end

	# wrappers to return the symbols of specific rules/periods/stats
	def rules_key(concept)
		self.rules.key(concept).to_sym
	end

	def period_key(concept)
		self.periods.key(concept).to_sym
	end

	def stat_key(concept)
		self.stats.key(concept).to_sym
	end

	# attempts to fetch the specific opbject from an id
	def self.fetch(sport_id=nil)
		sport = Sport.find(sport_id) if sport_id
		sport = Sport.first unless sport
		sport&.specific
	end

	private
		# generic setting method to be used for all setters
		def set_setting(key, value)
			self.settings = settings.merge(key => value)
		end

		# Retrieve event scoring stats for an event of the sport
		def get_event_scoring_stats(event_id:)
			concept = self.scoring["points"].to_sym	# lets split by scoring system
			s_stats = Stat.fetch(event_id:, concept:, create: false)
		end

		# Scan period stats for the value of a score
		# for a specific period & team
		def get_period_score(stats:, player_id:)
			s_val = Stat.by_player(player_id:, stats:).first
			s_val&.value
		end

		# load score for a period from the stats
		def read_score(period, stats, score, total)
			r_tot = (period == 0)	# get all points/games
			s_per = Stat.by_period(period:, stats:)
			p_for = get_period_score(stats: s_per, player_id: 0)
			p_opp = get_period_score(stats: s_per, player_id: -1)
			if p_for && p_opp	# we have a score for this period
				score[per] = {ours: p_for, opps: p_opp}	# load it to the hash
				unless r_tot	# if we already read the totals, this is unnecessary
					if s_system[:sets]	# different handling for sets
						(p_for > p_opp) ? (t_score[:ours] += 1) : (t_score[:opps] += 1)
					else # just add the points to the total
						total[:ours] += p_for
						total[:opps] += p_opp
					end
				end
			end
			r_tot	# did we just read a total?
		end

		# Scan period stats for the value of a score
		# for a specific period & team
		def set_period_score(event_id:, period:, player_id:, value:, stats:)
			concept = self.scoring[:points]	# lets split by scoring system
			update_stat(event_id:, period:, player_id:, concept:, stats: nil)
		end

		# Include a stat in an event
		def include_stat_in_event(event_id:, period: nil, player_id:, concept:, stats:)
			c_val = concept.is_a?(Integer) ? concept : self.stats[concept.to_s]
			nstat = Stat.fetch(concept: c_val, stats:).first
			unless nstat.id	# it is newly added we need to configure all fields
				nstat.event_id  = event_id
				nstat.player_id = player_id
			end
			nstat
		end
end
