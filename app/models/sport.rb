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
# simple class to have configurable Sports linked to the Club
class Sport < ApplicationRecord
	has_many :categories, dependent: :nullify
	has_many :divisions, dependent: :nullify
	has_many :teams, dependent: :nullify

	# Wrappers to define FieldComponents for views
	# METHODS MUST BE DEFINED IN SPORT-SPECIFIC OBJECTS!!
	# ========================================
	# fields to display match information - not title
	def match_show_fields(event, home: nil)
		raise "Must implement in Specific Sport object"
	end

	# fields to edit a match
	def match_form_fields(event, new: false)
		raise "Must implement in Specific Sport object"
	end

	# return period limitations for a match of this sport
	# depends on rules applied
	def match_outings(a_rules)
		raise "Must implement in Specific Sport object"
	end

	# grid to show/edit player outings for a match
	def outings_grid(event, outings, edit: false, home: nil, log: nil)
		raise "Must implement in Specific Sport object"
	end

	# grid to show/edit player stats for a match
	def stats_grid(event, edit: false, home: nil, log: nil)
		raise "Must implement in Specific Sport object"
	end

	# fields to display player's stats for training
	def player_training_stats_fields(event, player_id:)
		raise "Must implement in Specific Sport object"
	end

	# fields to track player training stats
	def player_training_stats_form_fields(event, player_id:)
		raise "Must implement in Specific Sport object"
	end

	# fields to show rules limits
	def rules_limits_fields
		raise "Must implement in Specific Sport object"
	end

	# default applicable rules for a category
	def default_rules(category)
		raise "Must implement in Specific Sport object"
	end

	# return rules that may apply to the Sport
	def rules_options
		raise "Must implement in Specific Sport object"
	end
	# ========================================
	# END OF SPORT-SPECIFIC METHODS

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

	# return quantity of match periods
	# based on whith rules apply
	def match_periods(rules)
		a_rules = self.rules.key(rules)
		periods = self.limits[a_rules]["periods"]
		periods ? periods["regular"] : 1
	end

	# returns the full score of a match (object of Event class)
	# {period1: {ours:, opps:}, period2: (etc.), tot: {ours:, opps:}}
	def match_score(event_id)
		s_stats  = get_event_scoring_stats(event_id)
		t_score  = {ours: 0, opps: 0}	# (period: 0 => t_score)
		score    = {}
		unless s_stats&.empty?
			r_tot = false
			self.periods.each_pair do |per, val|	#period==set if scoring by sets
				r_tot = read_score(val, s_stats, score, t_score)
			end
		end
		score[:tot] = t_score unless r_tot	# add total unless read
		score
	end

	# parse received stats hash from a form submission.
	# be in the form of an array of {key: value} pairs
	def parse_stats(event, stats_data)
		f_stats = []	# pass one: fetch all stats
		stats_data.each_pair do |key, val|
			keyarg = key.split("_")
			if keyarg.size == 1 # it's and event field, not a stat
				if keyarg[0] == "name"
					event.update(name: val)
				elsif keyarg[0] == "home"
					event.update(home: (val == "true"))
				end
			else
				f_stats << parse_form_stat(event.id, keyarg, val.to_i)
			end
		end

		update_stats(event, f_stats)
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

		# return label field for a stat
		def stat_label_field(label, abbr=true)
			{kind: "side-cell", value:label, align: "middle", class: "border px py"}
		end

		# generic wrapper to update a stat value
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

		# Retrieve event scoring stats for an event of the sport
		def get_event_scoring_stats(event_id)
			# lets split by scoring system
			concept = self.stats[self.scoring["points"]]
			s_stats = Stat.fetch(event_id:, concept:, create: false)
		end

		# Scan period stats for the value of a score
		# for a specific period & team
		def get_period_score(period:, player_id:, stats:)
			s_val = Stat.fetch(period:, player_id:, stats:, create: false).first
			s_val&.value
		end

		# load score for a period from the stats
		def read_score(period, stats, score, total)
			r_tot = (period == 0)	# get all points/games
			p_for = get_period_score(period:, player_id: 0, stats:)
			p_opp = get_period_score(period:, player_id: -1, stats:)
			if p_for && p_opp	# we have a score for this period
				score[period] = {ours: p_for, opps: p_opp}	# load it to the hash
				unless r_tot	# if we already read the totals, this is unnecessary
					if self.scoring[:sets]	# different handling for sets
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
		def include_stat_in_event(event_id:, period: nil, player_id:, concept:)
			c_val = concept.is_a?(Integer) ? concept : self.stats[concept.to_s]
			nstat = Stat.fetch(event_id:, period:, player_id:, concept: c_val).first
		end

		# return a normalised time string for a "seconds" value
		def time_string(seconds)
			tstr = ""
			count = seconds.to_i
			if (hours = (count / 3600).to_i) > 0
				tstr += "#{hours}º"
				count = (count - (hours * 3600)).to_i
			end
			if (mins = (count / 60).to_i) > 0
				tstr += "#{mins}'"
				count  = (count - (mins * 60)).to_i
			end
			tstr += "#{count}\""
		end

		# Retrieve/Create a stat from a form {key: val} hash
		def parse_form_stat(event_id, keyarg, value)
			player_id = case keyarg[0]	# player_id part
				when "ours" then 0
				when "opps" then -1
				else keyarg[0].to_i
			end
			period     = (keyarg[1].match?(/^(\d+)$/)	? keyarg[1].to_i : self.periods[keyarg[1]])
			concept    = keyarg[2].to_i
			stat       = Stat.fetch(event_id:, player_id:, period:, concept:, create: false).first
			stat     ||= Stat.new(event_id:, player_id:, period:, concept:)
			stat.value = value.to_i
			stat
		end

		# bulk update of stats
		def update_stats(event, f_stats)
			updated = nil
			Stat.transaction do
				f_stats.each do |stat|	# bind stats
					if stat.concept # if they have a valid concept
						if stat.changed?
							stat.save
							updated ||= true
						end
						unless event.stats.include?(stat)
							event.stats << stat
							updated ||= true
						end
					end
				end
			end
			return updated
		end
end
