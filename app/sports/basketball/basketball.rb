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
# Extension of the Sport class to Manage Basketball as a MudClub sport
class Basketball < Sport
	localized_as "sport.basketball"

	# --------------------------------------------------------------------------
	# Catalogs
	# --------------------------------------------------------------------------
	CATALOGS = {
		drill_categories: Catalog::Basketball::DrillCategories,
		court_modes: Catalog::Basketball::CourtModes,
		objects: Catalog::Basketball::Objects,
		periods: Catalog::Basketball::Periods,
		rules: Catalog::Basketball::Rules,
		statistics: Catalog::Basketball::Statistics
	}.freeze

	# Set default name only on brand-new records
	after_initialize if: :new_record? do
		self.name ||= self.class.default_sport_name
	end

	# --------------------------------------------------------------------------
	# Initialization
	# --------------------------------------------------------------------------
	def initialize(*args)
		super(*args)
		self.name   ||= "basketball"
		self.settings = default_basketball_settings if settings.blank?
	end

	# Populate missing settings groups on every instantiation, whether the
	# object is new or loaded from the DB. `find`/`first` bypass `initialize`,
	# so defaults must be applied here as well.
	#
	# Runs in-memory only — does not persist. For fresh records the value will
	# be written on `save`. For loaded records with stale/partial settings,
	# the repair lives only in this in-memory object (which is deterministic,
	# so it self-heals on next load as well).
	after_initialize do
		if settings[:scoring].blank? || settings[:limits].blank?
			write_attribute(:settings, default_basketball_settings.deep_merge(settings))
		end
	end

	# Ensure settings always merge defaults cleanly regardless of how the record was loaded
	def settings
		raw = (super || {}).deep_symbolize_keys
		if raw[:scoring].blank? || raw[:limits].blank?
			default_basketball_settings.deep_merge(raw)
		else
			raw
		end
	end

	# --------------------------------------------------------------------------
	# Delegated PORO accessors
	# --------------------------------------------------------------------------
	# ── Rules & Limits ───────────────────────────────────────
	def default_rules(category) = rules_config.default_rules(category)
	def match_periods(rule)     = rules_config.match_periods(rule)
	def match_outings(rule)     = rules_config.match_outings(rule)
	def rules_limits            = rules_config.rules_limits

	# ── Match Presenters ─────────────────────────────────────
	def match_show(event)             = match_presenter.match_fields(event, edit: false)
	def match_form(event, new: false) = match_presenter.match_fields(event, edit: true, new:)

	def outings_table(event, outings, edit: false, rdx: nil)
		match_presenter.outings_table(event, outings, edit:, rdx:)
	end

	def stats_table(event, edit: false, rdx: nil)
		match_presenter.stats_table(event, edit:, rdx:)
	end

	# ── Training Presenters ──────────────────────────────────
	def athlete_training_stats_show(event, athlete_id:)
		training_presenter.show(event, athlete_id:)
	end

	def athlete_training_stats_form(event, athlete_id:)
		training_presenter.form(event, athlete_id:)
	end

	# ── Stat Calculations ────────────────────────────────────
	def parse_stats(event, stats_data)
		stat_calculator.parse(event, stats_data)
	end

	# ── Symbols ──────────────────────────────────────────────
	def symbol(concept, type: :object, variant: "default")
		try_symbol(concept, namespace: self.name, type:, variant:) || super
	end

	def default_basketball_settings
		generic_settings.deep_merge(
			scoring: { sets: false, points: :pts },
			limits:  Rules::BasketballConfig::DEFAULT_LIMITS
		)
	end

	private
		def rules_config       = @rules_config       ||= Rules::BasketballConfig.new(self)
		def match_presenter    = @match_presenter    ||= Presenters::BasketballMatch.new(self)
		def training_presenter = @training_presenter ||= Presenters::BasketballTraining.new(self)
		def stat_calculator    = @stat_calculator    ||= Stats::BasketballCalculator.new(self)

		def accumulate_score(total:, ours:, opps:)
			total[:ours] += ours
			total[:opps] += opps
		end

		# Compatibility wrappers for private methods called via `send` in BasketballTest
		def show_shooting_data(...)  = training_presenter.send(:show_shooting_data, ...)
		def get_shooting_totals(...) = stat_calculator.compute_shooting_totals(...)
		def match_score_fields(...)  = match_presenter.send(:match_score_fields, ...)
end
