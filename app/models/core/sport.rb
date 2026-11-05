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

	# --------------------------------------------------------------------------
	# Associations
	# --------------------------------------------------------------------------
	has_many :categories, dependent: :nullify
	has_many :divisions,  dependent: :nullify
	has_many :teams,      dependent: :nullify

	# --------------------------------------------------------------------------
	# Common Sport API
	# --------------------------------------------------------------------------
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
	#
	# Example:
	#
	#   Sport(name: "Basketball").specific
	#   => Basketball.new(id: ...)
	def specific
		instance_of?(Sport) ? specific_instance : self
	end

	# Returns the specific implementation for a stored sport.
	def self.fetch(id = nil)
		(id ? find(id) : first)&.specific
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
	def catalog(name) = self.specific.class::CATALOGS.fetch(name.to_sym)
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
			rules: rules.enum,
			periods: periods.enum,
			stats: statistics.enum,
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
			when Symbol
				rule
			when Integer
				catalog(:rules).entry(rule).key
			else
				rule.to_sym
			end

		limits[key]
	end

	# ---------------------------------------------------------------------------
	# Generic stat persistence
	#
	# Concept may be passed as:
	#   - Symbol          :pts              (looked up via statistics.enum)
	#   - Integer         1                 (persisted value, as-is)
	#   - Catalog::Entry  statistics[:pts]  (uses .id)
	#
	# Legacy `player_id:` is accepted and resolved through Stat.translate_player_id,
	# so callers that still use it keep working through the deprecation window.
	# ---------------------------------------------------------------------------
	def update_stat(event_id:, concept:, value:, period: 0, kind: :athlete, athlete_id: nil, **legacy)
		if (pid = legacy[:player_id])
			kind, athlete_id =
				Stat.translate_player_id(pid.to_i, event_id, kind, athlete_id)
		end

		cid = concept_id(concept)

		stat = Stat.fetch(
			event_id:, period:, kind:, athlete_id:,
			concept: cid, create: false
		).first

		if stat
			stat.update!(value: value.to_i)
			stat
		else
			Stat.create!(
				Stat.build_attrs(
					event_id:, period:, concept: cid,
					kind:, athlete_id:, value: value.to_i
				)
			)
		end
	end

	# Bulk persistence of a hash produced by a form or by parse_stats.
	# Expected shape: { "<owner>_<period>_<concept_id>" => value, ... }
	# "owner" is an Assignment UUID (new) or an integer Player id (legacy).
	def update_stats(event_id:, stats_data:)
		stats_data = stats_data.to_unsafe_h if stats_data.respond_to?(:to_unsafe_h)
		stats_data = stats_data.to_h unless stats_data.is_a?(Hash)

		stats_data.each_pair do |key, raw|
			owner, period, concept = parse_stat_key(key)
			next unless owner && concept

			kind, athlete_id =
				if uuid?(owner)
					[ :athlete, owner ]
				else
					Stat.translate_player_id(owner.to_i, event_id, nil, nil)
				end
			next unless kind

			update_stat(
				event_id:, period:, concept:,
				kind:, athlete_id:, value: raw
			)
		end
	end

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

	# --------------------------------------------------------------------------
	# Generic helpers
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
	# Statistics / score handling
	#
	# Ownership of a stat is expressed by ONE of:
	#   - kind: :team   / :rival          (aggregate rows, athlete_id nil)
	#   - kind: :athlete, athlete_id:  (per-athlete rows)
	#
	# Legacy callers can still pass `player_id:`; `Stat.fetch` translates it
	# (with a deprecation warning) so no shim is needed here.
	# --------------------------------------------------------------------------

	# Returns the full score of a match:
	#   { period1: { ours:, opps: }, period2: { ... }, tot: { ours:, opps: } }
	def match_score(event_id)
		score = {}

		total = initial_total_score
		stats = scoring_stats(event_id)
		return { tot: total } if stats.blank?

		catalog(:periods).each do |period|
			read_period_score(period:, stats:, score:, total:)
		end

		score[:tot] ||= total
		score
	end

	# Delegate stats writers/readers to the specific sport. See the note above:
	# specific subclasses must NOT call super on these.
	def parse_stats(...) = delegate_to_specific(:parse_stats, ...)
	def period_key(...)  = delegate_to_specific(:period_key, ...)
	def rules_key(...)   = delegate_to_specific(:rules_key, ...)
	def stat_key(...)    = delegate_to_specific(:stat_key, ...)

	# --------------------------------------------------------------------------
	# Stat field rendering helpers
	#
	# IMPORTANT: `stats` is expected to be a collection already scoped to the
	# intended owner (assignment, period) by the caller. This method filters
	# only by `concept`.
	# --------------------------------------------------------------------------
	def label_item(value, **opts)
		{ kind: :label, value:, **opts }
	end

	# return label field for a stat
	def stat_label(label, abbr = true)
		{ kind: :side_cell, value: label, align: "middle", class: "border px-1 py-1" }
	end

	def stat_field(prefix, stats, stat, edit: false)
		value = stat_value(stats, stat)

		unless edit
			{ kind: :normal,
				value: format_stat_value(stat, value),
				align: "right" }
		else
			{ kind:  :number_box,
				key:   "#{prefix}#{stat.id}",
				value:,
				min:   stat[:minimum],
				max:   stat[:maximum],
				size:  stat[:size],
				units: stat[:units],
				step:  stat[:step] }.compact
		end
	end

	def stat_value(stats, stat)
		Stat.fetch(concept: stat.id, stats:, create: false).first&.value.to_i
	end

	private
		def catalog_enum(name)
			catalog(name).enum
		end

		def concept_id(concept)
			case concept
			when Integer        then concept
			when Symbol         then statistics.enum[concept]
			when Catalog::Entry then concept.id
			when String
				concept.match?(/\A\d+\z/) ? concept.to_i : statistics.enum[concept.to_sym]
			else
				concept.to_i
			end
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

		def specific_instance
			klass = name.to_s.camelize.safe_constantize

			raise NameError,
						"Sport '#{name}' has no implementation class." unless klass

			klass.find(id)
		end

		# ---------------------------------------------------------------------------
		# Score reading
		#
		# `period_score` accepts **owner via kwargs; `Stat.fetch` handles the
		# translation of legacy `player_id:` with a deprecation warning. New callers
		# should pass `kind: :team`, `kind: :rival`, or `kind: :athlete,
		# athlete_id: <uuid>`.
		# ---------------------------------------------------------------------------
		def format_stat_value(stat, value)
			case stat[:format]
			when :time then time_string(value)
			else            value
			end
		end

		def initial_total_score
			{ ours: 0, opps: 0 }
		end

		# Split "<owner>_<period>_<concept>" into three parts. Tolerates the
		# legacy two-part "<player_id>_<concept>" format with a warning.
		def parse_stat_key(key)
			parts = key.to_s.split("_")
			case parts.size
			when 3 then [ parts[0], parts[1], parts[2] ]
			when 2
				Rails.deprecator.warn("Sport: legacy 2-part stat key '#{key}'")
				[ parts[0], 0, parts[1] ]
			end
		end

		def period_score(period:, stats:, **owner)
			Stat.fetch(period:, stats:, create: false, **owner).first&.value
		end

		def read_period_score(period:, stats:, score:, total:)
			ours = period_score(period: period.id, kind: :team,  stats:)
			opps = period_score(period: period.id, kind: :rival, stats:)
			return if ours.nil? && opps.nil?

			ours = ours.to_i
			opps = opps.to_i

			score[period.key] = { ours:, opps: }
			return if period.key == :tot

			accumulate_score(total:, ours:, opps:)
		end

		def scoring_stats(event_id)
			Stat.fetch(event_id:, concept: statistics.enum[scoring[:points]], create: false)
		end

		def uuid?(value)
			value.to_s.match?(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
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
