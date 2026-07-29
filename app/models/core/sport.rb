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
#
# Generic Sport model.
#
# Sports persist configurable data shared by all clubs while delegating
# behaviour to their corresponding Specific Sport implementation.
#
class Sport < ApplicationRecord
	localized_as "core.sport"
	CATALOGS = {}.freeze

	#
	# --------------------------------------------------------------------------
	# Associations
	# --------------------------------------------------------------------------
	#

	has_many :categories, dependent: :nullify
	has_many :divisions,  dependent: :nullify
	has_many :teams,      dependent: :nullify

	#
	# --------------------------------------------------------------------------
	# Identity
	# --------------------------------------------------------------------------
	#

	def to_s
		label
	end

	#
	# Consistent helper for abstract methods.
	#
	def not_implemented!
		raise NotImplementedError,
					"#{self.class.name} must implement #{caller_locations(1, 1).first.label}"
	end

	#
	# --------------------------------------------------------------------------
	# Specific Sport implementation
	# --------------------------------------------------------------------------
	#

	#
	# Returns the runtime implementation for this sport.
	#
	# Example:
	#
	#   Sport(name: "Basketball").specific
	#   => Basketball.new(id: ...)
	#
	def specific
		instance_of?(Sport) ? specific_instance : self
	end

	#
	# Returns the specific implementation for a stored sport.
	#
	def self.fetch(id = nil)
		(id ? find(id) : first)&.specific
	end

	#
	# --------------------------------------------------------------------------
	# Generic Sport API
	#
	# These methods define the public interface every sport must expose.
	# Implementations belong to the corresponding Specific Sport.
	# --------------------------------------------------------------------------
	#

	#
	# Catalog lookup.
	#
	def catalog(name)
		self.class::CATALOGS.fetch(name.to_sym)
	end

	#
	# Symbol lookup.
	#
	# Generic because all sports use the SymbolRegistry.
	#
	def symbol(concept, type: :icon, variant: "default")
		try_symbol(concept,
							namespace: "sport",
							type:,
							variant:)
	end

	#
	# --------------------------------------------------------------------------
	# Canonical sport definitions
	# --------------------------------------------------------------------------
	#

	def rules
		catalog(:rules)
	end

	def periods
		catalog(:periods)
	end

	def statistics
		catalog(:statistics)
	end

	def court_modes
		catalog(:court_modes)
	end

	def objects
		catalog(:objects)
	end

	def limits
		settings.fetch(:limits, {})
	end

	def scoring
		settings.fetch(:scoring, {})
	end

	#
	# --------------------------------------------------------------------------
	# Sport behaviour
	# --------------------------------------------------------------------------
	#

	def court_name(court)
		delegate_to_specific(:court_name, court)
	end

	def match_show(event, home: nil)
		delegate_to_specific(:match_show, event, home:)
	end

	def match_form(event, new: false)
		delegate_to_specific(:match_form, event, new:)
	end

	def match_outings(rule)
		delegate_to_specific(:match_outings, rule)
	end

	def match_periods(rule)
		delegate_to_specific(:match_periods, rule)
	end

	def outings_table(event, outings, edit: false, home: nil, log: nil)
		delegate_to_specific(
			:outings_table,
			event,
			outings,
			edit:,
			home:,
			log:
		)
	end

	def stats_table(event, edit: false, home: nil, log: nil)
		delegate_to_specific(
			:stats_table,
			event,
			edit:,
			home:,
			log:
		)
	end

	def player_training_stats_show(event, player_id:)
		delegate_to_specific(
			:player_training_stats_show,
			event,
			player_id:
		)
	end

	def player_training_stats_form(event, player_id:)
		delegate_to_specific(
			:player_training_stats_form,
			event,
			player_id:
		)
	end

	def rules_limits
		delegate_to_specific(:rules_limits)
	end

	def default_rules(category)
		delegate_to_specific(:default_rules, category)
	end

	def rules_options
		catalog(:rules).options
	end

	#
	# --------------------------------------------------------------------------
	# Persistent configuration
	#
	# Catalogs provide canonical metadata.
	# Settings provide persistent overrides.
	# --------------------------------------------------------------------------
	#
	def generic_settings
		{
			rules: catalog(:rules).enum,
			periods: catalog(:periods).enum,
			stats: catalog(:statistics).enum,
			scoring: {},
			limits: {}
			}
	end

	def settings
		super&.deep_symbolize_keys || {}
	end

	def settings=(value)
		super(value&.to_h)
	end

	def limits_for(rule)
		key =
			case rule
			when Symbol
				rule
			when Integer
				catalog(:rules).entry(rule).key
			else
				rule.to_sym
			end

		limits[key]
	end

	#
	# --------------------------------------------------------------------------
	# Generic helpers
	# --------------------------------------------------------------------------
	#

	#
	# Formats a duration expressed in seconds.
	#
	def time_string(seconds)
		count  = seconds.to_i
		parts  = []

		if (hours = count / 3600).positive?
			parts << "#{hours}º"
			count -= hours * 3600
		end

		if (minutes = count / 60).positive?
			parts << "#{minutes}'"
			count -= minutes * 60
		end

		parts << "#{count}\""

		parts.join
	end

	# --------------------------------------------------------------------------
	# Statistics helpers
	# --------------------------------------------------------------------------
	def stat_field(prefix, stats, stat, edit: false)
		value = stat_value(stats, stat)

		unless edit
			{
				kind:  :normal,
				value: format_stat_value(stat, stat_value(stats, stat)),
				align: "right"
			}
		else
			{
				kind:  :number_box,
				key:   "#{prefix}#{stat.id}",
				value:,
				min: stat[:minimum],
				max: stat[:maximum],
				size: stat[:size],
				units: stat[:units],
				step: stat[:step]
			}.compact
		end
	end

	def stat_value(stats, stat)
		Stat.fetch(
			concept: stat.id,
			stats:,
			create: false
		).first&.value.to_i
	end

	#
	# --------------------------------------------------------------------------
	# Compatibility layer
	#
	# Deprecated wrappers preserved during the MudClub 2.0 migration.
	# These methods should gradually migrate into the corresponding
	# Specific Sport implementations.
	# --------------------------------------------------------------------------
	#

	# returns the full score of a match (object of Event class)
	# {period1: {ours:, opps:}, period2: (etc.), tot: {ours:, opps:}}
	def match_score(event_id)
		stats  = scoring_stats(event_id)
		return {} if stats.blank?

		score  = {}
		total = initial_total_score

		catalog(:periods).each do |period|
			read_period_score(period:, stats:, score:, total:)
		end

		score[:tot] ||= total

		score
	end

	def parse_stats(...)
		delegate_to_specific(:parse_stats, ...)
	end

	def update_stats(...)
		delegate_to_specific(:update_stats, ...)
	end

	def update_stat(...)
		delegate_to_specific(:update_stat, ...)
	end

	def include_stat_in_event(...)
		delegate_to_specific(:include_stat_in_event, ...)
	end

	def rules_key(...)
		delegate_to_specific(:rules_key, ...)
	end

	def period_key(...)
		delegate_to_specific(:period_key, ...)
	end

	def stat_key(...)
		delegate_to_specific(:stat_key, ...)
	end

	private

		def catalog_enum(name)
			catalog(name).enum
		end

		#
		# Centralized delegation helper.
		#
		def delegate_to_specific(method, ...)
			specific.public_send(method, ...)
		end

		def specific_instance
			klass = name.to_s.camelize.safe_constantize

			raise NameError,
						"Sport '#{name}' has no implementation class." unless klass

			klass.find(id)
		end

		def initial_total_score
			{ ours: 0, opps: 0 }
		end

		def period_score(period_id:, player_id:, stats:)
			Stat.fetch(period: period_id, player_id:, stats:, create: false).first&.value
		end

		def read_period_score(period:, stats:, score:, total:)
			ours = period_score(period_id: period.id, player_id: 0, stats:)
			opps = period_score(period_id: period.id, player_id: -1, stats:)
			return unless ours && opps

			score[period.key] = { ours: ours, opps: opps }
			return if period.key == :tot

			accumulate_score(total:, ours:, opps:)
		end

		def set_period_score(event_id:, period_id:, player_id:, value:)
			update_stat(
				event_id:,
				period_id:,
				player_id:,
				concept: statistics.enum[scoring[:points]],
				value:
			)
		end

		def scoring_stats(event_id)
			concept = statistics.enum[scoring[:points]]

			Stat.fetch(event_id:, concept:, create: false)
		end

		def format_stat_value(stat, value)
			case stat[:format]
			when :time
				time_string(value)
			else
				value
			end
		end

	protected

		#
		# Updates one setting while preserving the remaining configuration.
		#
		def set_setting(key, value)
			self.settings = settings.merge(key.to_sym => value)
		end

		# to update score totals
		def accumulate_score(...)
			not_implemented!
		end

		#
		# Generic SymbolRegistry wrapper.
		#
		def try_symbol(concept, namespace:, type:, variant:)
			SymbolRegistry.fetch(
				namespace:,
				type:,
				concept:,
				variant:
			)
		end
end
