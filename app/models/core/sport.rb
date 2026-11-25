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
	CATALOGS = { drill_categories: Catalog::DrillCategories }.freeze

	# --------------------------------------------------------------------------
	# Associations
	# --------------------------------------------------------------------------
	has_many :categories, dependent: :nullify
	has_many :divisions,  dependent: :nullify
	has_many :teams,      dependent: :nullify

	# --------------------------------------------------------------------------
	# Included Modules
	# --------------------------------------------------------------------------
	include HasSettings

	# --------------------------------------------------------------------------
	# Common Sport API
	# --------------------------------------------------------------------------

	# Returns the generic Sport instance if needed
	def generic
		instance_of?(Sport) ? self : becomes(Sport)
	end

	# Consistent helper for abstract methods.
	def not_implemented!
		raise NotImplementedError,
					"#{self.class.name} must implement #{caller_locations(1, 1).first.label}"
	end

	# Symbol lookup. Generic because all sports use the SymbolRegistry.
	def symbol(concept, type: :icon, variant: "default")
		try_symbol(concept, namespace: "sport", type:, variant:)
	end

	def to_s
		specific&.label || name
	end

	# --------------------------------------------------------------------------
	# Specific Sport implementation access
	# --------------------------------------------------------------------------

	# Returns the runtime implementation for this sport.
	# Casts generic Sport instances into their specific subclass in-memory (0 extra SQL queries)
	#
	# Example:
	#
	#   Sport(name: "Basketball").specific
	#   => Basketball.new(id: ...)
	def specific
		return self unless instance_of?(Sport)

		klass = specific_class
		becomes(klass)
	end

	# Automatically scopes queries when called on a subclass (e.g., Basketball.fetch)
	def self.fetch(sport = nil)
		scope = (self == Sport) ? all : where(name: default_sport_name)

		record =
			case sport
			when self    then sport
			when Sport   then sport.specific
			when Integer then scope.find_by(id: sport)
			when String, Symbol
				str = sport.to_s
				str.match?(/\A\d+\z/) ? scope.find_by(id: str.to_i) : scope.find_by(name: str.downcase)
			when nil
				scope.first
			else
				raise ArgumentError, "Unsupported sport lookup: #{sport.class}"
			end

		record&.specific
	end

	# --------------------------------------------------------------------------
	# Generic Sport API
	#
	# These methods define the public interface every sport must expose.
	# Implementations belong to the corresponding Specific Sport.
	# --------------------------------------------------------------------------

	# --------------------------------------------------------------------------
	# Catalogs provide canonical metadata.
	# --------------------------------------------------------------------------
	def catalog(name)
		key = name.to_sym
		specific_class = self.specific.class
		return specific_class::CATALOGS[key] if specific_class::CATALOGS.key?(key)
		Sport::CATALOGS.fetch(key)
	end

	def court_modes   = catalog(:court_modes)
	def periods       = catalog(:periods)
	def rules         = catalog(:rules)
	def objects       = catalog(:objects)
	def statistics    = catalog(:statistics)

	# --------------------------------------------------------------------------
	# Persistent configuration settings
	# --------------------------------------------------------------------------
	def generic_settings
		{
			rules:   rules.enum,
			periods: periods.enum,
			stats:   statistics.enum,
			scoring: {},
			limits:  {}
		}
	end

	def scoring
		@scoring ||= begin
			raw = settings.fetch(:scoring, {})
			raw.merge(points: raw[:points]&.to_sym, sets: raw[:sets])
		end
	end

	def limits
		@limits ||= settings.fetch(:limits, {})
	end

	def limits_for(rule)
		key =
			case rule
			when Symbol  then rule
			when Integer then catalog(:rules).entry(rule).key
			else              rule.to_sym
			end

		limits[key]
	end

	# --------------------------------------------------------------------------
	# Delegated PORO operations (Stats, Scores, Fields)
	# --------------------------------------------------------------------------
	def update_stat(**args)                = stat_writer.update_stat(**args)
	def update_stats(event_id:, stats_data:) = stat_writer.update_stats(event_id:, stats_data:)
	def match_score(event_id)              = score_reader.match_score(event_id)

	def label_item(value, **opts)          = field_builder.label_item(value, **opts)
	def stat_label(label, abbr = true)     = field_builder.stat_label(label, abbr)
	def stat_field(prefix, stats, stat, edit: false)
		field_builder.stat_field(prefix, stats, stat, edit:)
	end
	def stat_value(stats, stat)            = field_builder.stat_value(stats, stat)

	# --------------------------------------------------------------------------
	# Sport behaviour
	# NOTE: specific subclasses MUST NOT call `super` on these methods. The
	# delegation contract is: `Sport#foo` → `specific.foo`, and `specific.foo`
	# is the terminal call. See `delegate_to_specific` for the guard.
	# --------------------------------------------------------------------------
	def athlete_training_stats_form(event, athlete_id:)
		delegate_to_specific(:athlete_training_stats_form, event, athlete_id:)
	end

	def athlete_training_stats_show(event, athlete_id:)
		delegate_to_specific(:athlete_training_stats_show, event, athlete_id:)
	end

	def default_rules(category)       = delegate_to_specific(:default_rules, category)
	def match_form(event, new: false) = delegate_to_specific(:match_form, event, new:)
	def match_show(event)             = delegate_to_specific(:match_show, event)
	def match_periods(rule)           = delegate_to_specific(:match_periods, rule)
	def match_outings(rule)           = delegate_to_specific(:match_outings, rule)

	def outings_table(event, outings, edit: false, rdx: nil)
		delegate_to_specific(:outings_table, event, outings, edit:, rdx:)
	end

	def rules_limits  = delegate_to_specific(:rules_limits)
	def rules_options = rules.option_list

	def stats_table(event, edit: false, rdx: nil)
		delegate_to_specific(:stats_table, event, edit:, rdx:)
	end

	def parse_stats(...) = delegate_to_specific(:parse_stats, ...)
	def period_key(...)  = delegate_to_specific(:period_key, ...)
	def rules_key(...)   = delegate_to_specific(:rules_key, ...)
	def stat_key(...)    = delegate_to_specific(:stat_key, ...)

	# --------------------------------------------------------------------------
	# Formatting Helpers
	# --------------------------------------------------------------------------
	def court_name(court)
		court_entry =
			case court
			when Catalog::Entry then court
			when String         then court_modes.fetch(court)
			when Integer        then court_modes.entry(court)
			end

		court_entry.label
	end

	# Formats a duration expressed in seconds.
	def time_string(seconds)
		count = seconds.to_i
		parts = []

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

	private
		def stat_writer   = @stat_writer   ||= Sport::StatWriter.new(self)
		def score_reader  = @score_reader  ||= Sport::ScoreReader.new(self)
		def field_builder = @field_builder ||= Sport::FieldBuilder.new(self)

		def catalog_enum(name)
			catalog(name).enum
		end

		def specific_class
			klass = name.to_s.classify.safe_constantize
			unless klass && klass < Sport
				raise NameError, "Sport '#{name}' has no valid implementation subclass."
			end
			klass
		end

		def self.default_sport_name
			name.demodulize.underscore
		end

		# ---------------------------------------------------------------------------
		# Delegation
		#
		# Raises if `self` is already the specific class (which happens only when a
		# specific subclass calls `super`). This converts what used to be an
		# infinite recursion into a clear, one-shot error.
		# ---------------------------------------------------------------------------
		def delegate_to_specific(method, ...)
			target = specific

			if target.equal?(self)
				raise NotImplementedError,
							"#{self.class.name}##{method} called with no specific implementation " \
							"(specific class missing or super called from a specific subclass)"
			end

			target.public_send(method, ...)
		end

	protected

		# Updates one setting while preserving the remaining configuration.
		def set_setting(key, value)
			self.settings = settings.merge(key.to_sym => value)
		end

		# to update score totals
		def accumulate_score(...)
			not_implemented!
		end

		# Generic SymbolRegistry wrapper.
		def try_symbol(concept, namespace:, type:, variant:)
			SymbolRegistry.fetch(namespace:, type:, concept:, variant:)
		end
end
