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
# frozen_string_literal: true

# frozen_string_literal: true

#
# Localizable
#
# Shared localization API for models, catalogs and other domain objects.
#
# Classes including this concern must set their i18n_scope using:
#
#   localized_as :organization, :club
#
# Examples:
#
#   Club.label                         # => "Club"
#   Club.label(:plural)                # => "Clubs"   (uses label.plural or label_plural)
#   Club.label(:short)                 # => "Club"    (uses short or short)
#
#   Club.attr(:name)                   # => "Name"
#   Club.attr(:name, :short)           # => "Name"    (uses name_short or name.short)
#
#   Club.msg(:created)                 # => "Club created."
#
#   Club.val(:athlete)                 # => "Athlete"
#   Club.val(:athlete, :plural)        # => "Athletes"
#   Club.val(:athlete, :short)         # => "Ath."
#
module Localizable
	extend ActiveSupport::Concern

	#
	# Available presentation variants.
	#
	VARIANT_SUFFIXES = {
		label: nil,
		short: "_short",
		hint: "_hint",
		description: "_description",
		tooltip: "_tooltip"
	}.freeze

	GRAMMATICAL_FORMS = %i[single plural].freeze
	TEXT_VARIANTS = %i[label short hint description tooltip].freeze

	included do
		class_attribute :_i18n_scope, instance_accessor: false, default: nil
		class_attribute :_i18n_members_scope, instance_accessor: false, default: :fields
	end

	# Instance helpers
	def label(...) = self.class.label(...)
	def attr(...) = self.class.attr(...)
	def msg(...) = self.class.msg(...)
	def val(...) = self.class.val(...)
	def t_path(...) = self.class.t_path(...)

	class_methods do
		# -------------------------------------------------------------------------
		# Scope configuration
		# -------------------------------------------------------------------------

		def localized_as(*parts)
			self._i18n_scope = parts.flatten.compact.join(".")
		end

		def i18n_scope
			return _i18n_scope if _i18n_scope.present?
			raise NotImplementedError,
						"#{name} must set its i18n_scope using localized_as or by overriding .i18n_scope"
		end

		def i18n_members_scope
			_i18n_members_scope || :fields
		end

		def members_scope(scope)
			self._i18n_members_scope = scope
		end

		# -------------------------------------------------------------------------
		# Core translation method
		# -------------------------------------------------------------------------

		#
		# Translate a member (field, message, value) with flexible key resolution.
		#
		# Tries:
		#   1. Flat suffix: "#{base}_#{suffix}"
		#   2. Nested key:  "#{base}.#{suffix}"
		#   3. Base key:    "#{base}"
		#
		def translate_member(section, member, variant: :label, form: :single)
			base_key = "#{i18n_scope}.#{section}.#{member}"

			# Build the suffix for this combination
			suffix = ""
			suffix += "_plural" if form == :plural
			if variant != :label
				variant_suffix = VARIANT_SUFFIXES[variant]
				suffix += variant_suffix if variant_suffix
			end

			# Generate possible keys in order of preference
			candidates = []

			# 1. Flat suffix (e.g., "label_plural")
			if suffix.present?
				candidates << "#{base_key}#{suffix}"
			end

			# 2. Nested suffix (e.g., "label.plural")
			if suffix.present?
				key_part = suffix.sub(/^_/, "")  # remove leading underscore
				candidates << "#{base_key}.#{key_part}"
			end

			# 3. Base key (no suffix)
			candidates << base_key

			# Try each candidate
			candidates.uniq.each do |key|
				value = I18n.t(key, default: nil)
				return value if value.present?
			end

			# Final fallback
			fallback_to_humanize(member, variant, form)
		end

		# -------------------------------------------------------------------------
		# Flexible label method
		# -------------------------------------------------------------------------
		#
		# Supports:
		#   - Class label: label
		#   - Plural form: label(:plural) or label(form: :plural)
		#   - Short form:  label(:short)  or label(variant: :short)
		#   - Scoped lookup: label(:name, scope: :fields)
		#
		def label(member = nil, scope: nil, variant: :label, form: :single, gender: :neutral)
			# -----------------------------------------------------------------------
			# Shorthand
			# -----------------------------------------------------------------------

			if member.is_a?(Symbol)
				if GRAMMATICAL_FORMS.include?(member)
					form = member
					member = nil
				elsif TEXT_VARIANTS.include?(member)
					variant = member
					member = nil
				end
			end

			# -----------------------------------------------------------------------
			# Class label
			# -----------------------------------------------------------------------

			if member.nil?
				base_key   = "#{i18n_scope}.label"
				candidates = []

				suffix = +""

				suffix << "_plural" if form == :plural

				if variant != :label
					variant_suffix = VARIANT_SUFFIXES[variant]
					suffix << variant_suffix if variant_suffix
				end

				#
				# Preferred lookups
				#

				if suffix.present?
					# Flat style:
					#   participation.membership.label_plural_short
					candidates << "#{base_key}#{suffix}"

					# Nested style:
					#   participation.membership.label.plural_short
					candidates << "#{base_key}.#{suffix.delete_prefix('_')}"
				else
					# Default grammatical form
					#   participation.membership.label.single
					candidates << "#{base_key}.#{form}"
				end

				#
				# Legacy / hash fallback
				#

				candidates << base_key

				candidates.uniq.each do |key|
					value = I18n.t(key, default: nil)

					next if value.blank?

					# Hash fallback (legacy locale structure)
					if value.is_a?(Hash)
						candidate =
							value[form] ||
							value[form.to_s] ||
							value[:single] ||
							value["single"]

						return candidate if candidate.present?
					else
						return value
					end
				end

				#
				# Final fallback
				#

				return name.demodulize.titleize
			end

			# -----------------------------------------------------------------------
			# Member lookup
			# -----------------------------------------------------------------------

			section =
				case scope
				when :attribute, :field, :fields then :fields
				when :message, :messages          then :messages
				when :value, :values              then :values
				else
					i18n_members_scope
				end

			translate_member(
				section,
				member,
				variant:,
				form:
			)
		end

		# -------------------------------------------------------------------------
		# Convenience shortcuts
		# -------------------------------------------------------------------------

		def attr(member, variant = :label)
			translate_member(:fields, member, variant: variant)
		end

		def msg(member, variant = :label)
			translate_member(:messages, member, variant: variant)
		end

		def val(member, variant = :label, form: :single)
			translate_member(:values, member, variant: variant, form: form)
		end

		def t_path(*parts)
			# If the first part is a string, treat as absolute (join all parts).
			# If the first part is a symbol, treat as relative to i18n_scope.
			if parts.first.is_a?(String)
				key = parts.join(".")
			else
				key = "#{i18n_scope}.#{parts.join(".")}"
			end
			I18n.t(key)
		end

		private

			def fallback_to_humanize(member, variant, form)
				base = member.to_s.humanize
				base = base.pluralize if form == :plural

				return base if variant == :label || variant == :short

				case variant
				when :hint then "#{base} hint"
				when :description then "#{base} description"
				when :tooltip then "#{base} tooltip"
				else base
				end
			end
	end
end
