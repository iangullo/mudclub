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

	# multi-language string for sport name
	def to_s
		I18n.t("sport.#{self.name}")
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
	def rules
		settings&.fetch(:rules, {})
	end

	# Setter method for updating the rules mapping
	def rules=(value)
		set_setting(:rules, value)
	end

	# Getter method for accessing the Sport scoring_system. Should
	# identify specific Stats concepts to calculate scoring
	# if any of them are nil, they will be ignored
	# value = {sets: true/false, points: :points_concept}
	def scoring_system
		settings&.fetch(:scoring, {})
	end

	# Setter method for updating the scoring_system mapping
	# value = {sets: true/false, points: :points_concept}
	def scoring_system=(value)
		set_setting(:scoring, value)
	end

	# Getter method for accessing the stat mapping
	def stats
		settings&.fetch(:stats, {})
	end

	# Setter method for updating the stat mapping
	def stats=(value)
		set_setting(:stats, value)
	end

	# Getter method for accessing the Sport rules mapping
	def stat_kinds
		settings&.fetch(:stat_kinds, {})
	end

	# Setter method for updating the rules mapping
	def stat_kinds=(value)
		set_setting(:stat_kinds, value)
	end

	# are competition fixtures split in periods?
	def periods
		settings&.fetch(:periods, {})
	end

	# Setter method for updating the periods mapping
	def periods=(value)
		set_setting(:periods, value)
	end

	# returns the score of a match (object of Event class)
	# our team always first - to be tweaked in controllers
	def match_score(event_id:)
		s_stats  = get_event_scoring_stats(event_id:)
		t_score  = {ours: 0, opps: 0}	# (period: 0 => t_score)
		score    = {}
		self.periods.each_pair do |per, val|	#period==set if scoring by sets
			r_tot = (per.to_sym == :tot)	# get all points/games
			s_per = Stat.by_period(period: val, stats: s_stats)
			p_for = get_period_score(stats: s_per, player_id: 0)
			p_opp = get_period_score(stats: s_per, player_id: -1)
			if p_for && p_opp	# we have a score for this period
				score[per] = {ours: p_for, opps: p_opp}	# load it to the hash
				unless r_tot	# if we already read the totals, this is unnecessary
					if s_system[:sets]	# different handling for sets
						(p_for > p_opp) ? (t_score[:ours] += 1) : (t_score[:opps] += 1)
					else # just add the points to the total
						t_score[:ours] += p_for
						t_score[:opps] += p_opp
					end
				end
			end
		end
		score[:tot] = t_score unless r_tot	# add total unless read
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

	# fields to display match period
	def match_period_grid(event, edit: nil)
		raise "Must implement in Specific Sport object"
	end

	# fields to track player training stats
	def player_training_header_fields(event_id:, player_id:)
		raise "Must implement in Specific Sport object"
	end

	# fields to track player training stats
	def player_training_stats_fields(event_id:, player_id:)
		raise "Must implement in Specific Sport object"
	end

	# fields to track player training stats
	def player_training_stats_form_fields(event_id:, player_id:)
		raise "Must implement in Specific Sport object"
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

	# return the right symbol for a rule concept
	def rules_key(concept)
		self.rules.key(concept).to_sym
	end

	# return the right symbol for a rule concept
	def period_key(concept)
		self.periods.key(concept).to_sym
	end

	# return the right symbol for a stat concept
	def stat_key(concept)
		self.stats.key(concept).to_sym
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


	private
		# generic setting method to be used for all setters
		def set_setting(key, value)
			self.settings = settings.merge(key => value)
		end

		# Retrieve event scorign stats for an event of the sport
		def get_event_scoring_stats(event_id:)
			concept = self.scoring_system[:points]	# lets split by scoring system
			s_stats  = Stat.fetch(event_id:, concept:)
		end
		# Scan period stats for the value of a score
		# for a specific period & team
		def get_period_score(stats:, player_id:)
			s_val = Stat.by_player(player_id:, stats:).first
			s_val&.value
		end
		# Scan period stats for the value of a score
		# for a specific period & team
		def set_period_score(event_id:, period:, player_id:, value:, stats:)
			concept = self.scoring_system[:points]	# lets split by scoring system
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
