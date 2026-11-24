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
# along with this program.  If not, see <https://gnu.org>.
#
# contact email - iangullo@gmail.com.
#
# frozen_string_literal: true

#
# Localizable
#
# Shared localization API for models, catalogs, UI concepts and other domain objects.
#
# Classes including this concern declare their locale scope with:
#
#   localized_as :organization, :club
#
# Examples
#
#   Club.label
#   Club.label(:plural)
#   Club.label(:short)
#   Club.label(:plural, :female)
#
#   Club.fld(:name)
#   Club.msg(:created)
#   Club.val(:athlete)
#   UI::Status.val(:active, :plural, :female)
#   UI::Status.val(:active, Club)
#   UI::Status.val(:active, Basketball.term_ref(:field_of_play))
#
#   Club.term(:athlete)
#   Club.term(:athlete, :plural)
#   Club.term(:coach, :short)
#
module Localizable
	extend ActiveSupport::Concern

	#--------------------------------------------------------------------------
	# Translation conventions
	#--------------------------------------------------------------------------

	VARIANT_SUFFIXES = {
		label:       nil,
		short:       "_short",
		hint:        "_hint",
		description: "_description",
		tooltip:     "_tooltip"
	}.freeze

	GRAMMATICAL_FORMS = %i[
		single
		plural
	].freeze

	TEXT_VARIANTS = %i[
		label
		short
		hint
		description
		tooltip
		home
		won
		lost
		roster
	].freeze

	GENDERS = %i[male female neutral].freeze

	# Value object used to pass a term's grammatical gender context to UI helpers
	TermRef = Data.define(:key, :sport, :club)

	#--------------------------------------------------------------------------
	# Module-level cache & helpers
	#--------------------------------------------------------------------------

	def self.gender_cache
		@gender_cache ||= {}
	end

	def self.clear_gender_cache!
		@gender_cache&.clear
	end

	def self.for_term(key, sport: nil, club: nil)
		TermRef.new(key:, sport:, club:)
	end

	#--------------------------------------------------------------------------
	# Configuration
	#--------------------------------------------------------------------------

	included do
		class_attribute :_i18n_key_scope, instance_accessor: false, default: :fields
		class_attribute :_i18n_scope, instance_accessor: false, default: nil
	end

	#--------------------------------------------------------------------------
	# Instance convenience wrappers
	#--------------------------------------------------------------------------

	TRANSLATION_HELPERS = %i[
		label
		act
		term
		term_gender
		fld
		msg
		val
		que
		t_path
	].freeze

	TRANSLATION_HELPERS.each do |helper|
		define_method(helper) do |*args, **kwargs, &block|
			self.class.public_send(helper, *args, **kwargs, &block)
		end
	end

	def term_ref(key, sport: nil, club: nil)
		resolved_sport = sport || (self if respond_to?(:i18n_scope) && i18n_scope.start_with?("sport."))
		self.class.term_ref(key, sport: resolved_sport, club:)
	end

	#--------------------------------------------------------------------------
	# Class API
	#--------------------------------------------------------------------------

	class_methods do
		# Declares the locale scope used by this class.
		#
		# Example:
		#
		#   localized_as :identity, :person
		def localized_as(*parts)
			self._i18n_scope = parts.flatten.compact.join(".")
		end

		# Declares which subsection key helpers
		# (label(:...), fld, msg, val...) should default to.
		def key_scope(scope)
			self._i18n_key_scope = scope.to_sym
		end

		# try to infer the gender to be used when generating a string
		def i18n_gender(locale: I18n.locale)
			cache_key = [ :scope, i18n_scope, locale.to_sym ]
			Localizable.gender_cache.fetch(cache_key) do
				raw = I18n.t("#{i18n_scope}.gender", locale:, default: nil) ||
							I18n.t("#{i18n_scope}.label.gender", locale:, default: nil)
				sym = raw&.to_sym
				Localizable.gender_cache[cache_key] = GENDERS.include?(sym) ? sym : :neutral
			end
		end

		# Returns the configured locale scope.
		def i18n_scope
			return _i18n_scope if _i18n_scope.present?

			raise NotImplementedError,
						"#{name} must declare localized_as(...) or override .i18n_scope"
		end

		# Default subsection for key lookups.
		def i18n_key_scope
			_i18n_key_scope || :fields
		end

		#--------------------------------------------------------------------------
		# Public translation API
		#--------------------------------------------------------------------------

		# Generic label resolver.
		#
		# Examples
		#
		#   Club.label
		#   Club.label(:plural)
		#   Club.label(:short)
		#
		#   Club.label(:name)
		#   Club.label(:name, scope: :fields)
		def label(*modifiers, **options)
			args = normalize_translation_arguments(*modifiers, **options)

			if args[:key]
				translate_key_label(**args)
			else
				translate_class_label(**args)
			end
		end

		# Resolves terminology that may be overridden by
		# Club settings or Sport locale.
		#
		# Examples
		#
		#   Club.term(:athlete)
		#   Club.term(:athlete, form: :plural)
		#   Club.term(:coach, variant: :short)
		def term(key, *modifiers, club: nil, sport: nil, fallback: nil, **options)
			args = normalize_translation_arguments(*modifiers, key:, **options)

			Vocabulary.term(
				args[:key],
				form:           args[:form],
				gender:         args[:gender],
				variant:        args[:variant],
				override_scope: resolve_override_scope(sport),
				club:,
				fallback:
			)
		end


		# Resolves the grammatical gender of a term in the active locale,
		# accounting for Club settings and Sport locale overrides.
		def term_gender(key, club: nil, sport: nil, locale: I18n.locale)
			if club.present? && club.respond_to?(:term_gender)
				club_gender = club.term_gender(key, locale:)&.to_sym
				return club_gender if GENDERS.include?(club_gender)
			end

			override_scope = resolve_override_scope(sport)
			cache_key      = [ :term, override_scope, key.to_sym, locale.to_sym ]

			Localizable.gender_cache.fetch(cache_key) do
				candidates = [
					override_scope && "#{override_scope}.terms.#{key}.gender",
					"vocabulary.terms.#{key}.gender"
				].compact

				resolved = :neutral
				candidates.each do |path|
					raw = I18n.t(path, locale:, default: nil)
					sym = raw&.to_sym
					if GENDERS.include?(sym)
						resolved = sym
						break
					end
				end

				Localizable.gender_cache[cache_key] = resolved
			end
		end

		# Builds a TermRef scoped to this class if it represents a sport.
		def term_ref(key, sport: nil, club: nil)
			resolved_sport = sport || (self if i18n_scope.start_with?("sport."))
			Localizable.for_term(key, sport: resolved_sport, club:)
		end

		# Convenience wrappers
		TRANSLATION_SECTIONS = { act: :actions, fld: :fields, msg: :messages, val: :values, que: :questions }.freeze

		TRANSLATION_SECTIONS.each do |method_name, scope|
			define_method(method_name) do |key, *modifiers, **options|
				args = normalize_translation_arguments(*modifiers, key, **options)
				translate_key_label(**args, scope:)
			end
		end

		# Flexible translation path.
		#
		# Relative:
		#
		#   Person.t_path(:fields, :name)
		#
		# Absolute:
		#
		#   Person.t_path("identity.person.fields.name")
		def t_path(*parts, **options)
			key =
				if parts.first.is_a?(String)
					parts.join(".")
				else
					"#{i18n_scope}.#{parts.join('.')}"
				end

			I18n.t(key, **options)
		end

		private

			def i18n_candidate_scopes
				[ i18n_scope ]
			end

			def resolve_override_scope(sport)
				if sport
					sport.i18n_scope
				elsif i18n_scope.start_with?("sport.")
					i18n_scope
				end
			end

			#--------------------------------------------------------------------------
			# Label argument normalization
			#--------------------------------------------------------------------------

			def normalize_translation_arguments(*args, key: nil, scope: nil, variant: :label, form: :single, gender: nil, for_model: nil, **options)
				args.flatten.compact.each do |arg|
					if arg.is_a?(Symbol)
						if GRAMMATICAL_FORMS.include?(arg)
							form = arg
						elsif TEXT_VARIANTS.include?(arg)
							variant = arg
						elsif GENDERS.include?(arg)
							gender = arg
						else
							key ||= arg
						end
					elsif gender_target?(arg)
						for_model = arg
					else
						key ||= arg
					end
				end

				resolved_gender = gender || resolve_gender(for_model, locale: options[:locale] || I18n.locale)

				{ key:, scope:, variant:, form:, gender: resolved_gender, **options }
			end

			def gender_target?(arg)
				arg.is_a?(Localizable::TermRef) ||
					arg.respond_to?(:gender) ||
					arg.respond_to?(:i18n_gender) ||
					arg.class.respond_to?(:i18n_gender)
			end

			def resolve_gender(target, locale: I18n.locale)
				return i18n_gender(locale:) if target.nil?

				raw =
					if target.is_a?(Localizable::TermRef)
						term_gender(target.key, club: target.club, sport: target.sport, locale:)
					elsif target.respond_to?(:gender) && target.gender.present?
						target.gender
					elsif target.respond_to?(:i18n_gender)
						target.i18n_gender(locale:)
					elsif target.class.respond_to?(:i18n_gender)
						target.class.i18n_gender(locale:)
					end

				sym = raw&.to_sym
				GENDERS.include?(sym) ? sym : :neutral
			end

			#--------------------------------------------------------------------------
			# Candidate string keys generation
			#--------------------------------------------------------------------------
			def build_candidates(base_key, variant:, form:, gender: :neutral)
				# Suffix parts, in order: form, variant, gender.
				# Omit parts that are at their default value.
				parts = []
				parts << "plural" if form == :plural
				parts << VARIANT_SUFFIXES[variant].to_s.delete_prefix("_") if variant != :label
				parts << "female" if gender == :female

				candidates = []

				if parts.any?
					suffix = parts.join("_")
					candidates << "#{base_key}_#{suffix}"    # flat: athlete_plural
					candidates << "#{base_key}.#{suffix}"    # dotted: athlete.plural
				else
					candidates << "#{base_key}.#{form}"      # athlete.single
				end

				# Female lookups fall back to the neutral form before giving up.
				if gender == :female
					neutral = parts - [ "female" ]
					if neutral.any?
						n = neutral.join("_")
						candidates << "#{base_key}_#{n}"
						candidates << "#{base_key}.#{n}"
					end
				end

				candidates << "#{base_key}.label"
				candidates << base_key
				candidates.uniq
			end

			#--------------------------------------------------------------------------
			# Class labels
			#--------------------------------------------------------------------------
			def translate_class_label(variant:, form:, gender: :neutral, **interp)
				lookup_candidates(
					build_candidates("#{i18n_scope}.label", variant:, form:, gender:),
					fallback: name.demodulize.titleize,
					interp:
				)
			end

			#--------------------------------------------------------------------------
			# key labels
			#--------------------------------------------------------------------------
			def translate_key_label(key:, scope:, variant:, form:, gender: :neutral, **interp)
				section =
					case scope
					when :attribute, :field, :fields then :fields
					when :message, :messages         then :messages
					when :value, :values             then :values
					when :action, :actions           then :actions
					when :question, :questions       then :questions   # ← add
					else                                  i18n_key_scope
					end

				candidates = i18n_candidate_scopes.flat_map do |prefix|
					build_candidates("#{prefix}.#{section}.#{key}", variant:, form:, gender:)
				end

				lookup_candidates(candidates, fallback: fallback_to_humanize(key, variant, form), interp:)
			end

			#--------------------------------------------------------------------------
			# Lookup helpers
			#--------------------------------------------------------------------------
			def lookup_candidates(candidates, fallback:, interp: {})
				candidates.each do |key|
					value = I18n.t(key, default: nil, **interp)
					next if value.blank?

					extracted = extract_translation(value)
					return extracted if extracted.present?
				end

				fallback
			end

			def extract_translation(value)
				return value unless value.is_a?(Hash)

				value[:single] ||
					value["single"] ||
					value[:label] ||
					value["label"]
			end

			#--------------------------------------------------------------------------
			# Fallback
			#--------------------------------------------------------------------------

			def fallback_to_humanize(key, variant, form)
				text = key.to_s.humanize

				text = text.pluralize if form == :plural

				return text if %i[label short].include?(variant)

				case variant
				when :hint
					"#{text} hint"

				when :description
					"#{text} description"

				when :tooltip
					"#{text} tooltip"

				else
					text
				end
			end
	end
end
