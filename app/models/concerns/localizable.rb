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

#
# Localizable
#
# Shared localization API for models, catalogs and other domain objects.
#
# Classes including this concern must implement:
#
#   i18n_scope
#
# and may optionally override:
#
#   i18n_members_scope
#
# Examples
#
#   Person.label
#   Person.label(:name)
#   Person.label(:name, :short)
#   Person.label(:name, :plural)
#   Person.label(:name, :short, :plural)
#
#   Catalog::Months.label(:january)
#   Catalog::Months.label(:january, :short)
#
module Localizable
	extend ActiveSupport::Concern

	#
	# Available presentation styles.
	#
	TEXT_VARIANTS = {
		label: {
			lookup: :label,
			fallback: nil
		},
		short: {
			lookup: :short,
			fallback: :label
		},
		hint: {
			lookup: :hint,
			fallback: :description
		},
		description: {
			lookup: :description,
			fallback: :label
		},
		tooltip: {
			lookup: :tooltip,
			fallback: :hint
		}
	}.freeze

	#
	# Supported grammatical forms.
	#
	GRAMMATICAL_FORMS = %i[
		single
		plural
	].freeze

	#
	# Supported grammatical genders.
	#
	# Included from the beginning to avoid future API changes.
	#
	GRAMMATICAL_GENDERS = %i[
		neutral
		masculine
		feminine
	].freeze

	#
	# Instance helper.
	#
	# Delegates localization requests to the class.
	#
	def label(...)
		self.class.label(...)
	end

	class_methods do
		#
		# Root I18n scope.
		#
		def i18n_scope
			raise NotImplementedError,
						"#{name} must implement .i18n_scope"
		end

		#
		# Scope used for translatable members.
		#
		# Models typically use:
		#
		#   fields
		#
		# Catalogs typically use:
		#
		#   values
		#
		def i18n_members_scope
			:fields
		end

		#
		# Human-readable localized text.
		#
		# Examples:
		#
		#   label
		#   label(form: :plural)
		#   label(variant: :short)
		#
		#   label(:name)
		#   label(:name, style: :short)
		#   label(:name, form: :plural)
		#   label(:president, gender: :feminine)
		#
		def label(member = nil, variant: :label, form: :single, gender: :neutral)
			unless TEXT_VARIANTS.key?(variant)
				raise ArgumentError,
							"Unknown label style: #{style.inspect}"
			end

			unless GRAMMATICAL_FORMS.include?(form)
				raise ArgumentError,
							"Unknown grammatical form: #{form.inspect}"
			end

			unless GRAMMATICAL_GENDERS.include?(gender)
				raise ArgumentError,
							"Unknown grammatical gender: #{gender.inspect}"
			end

			base = i18n_scope

			if member
				base += ".#{i18n_members_scope}.#{member}"
			end

			build_lookup_chain(variant, form, gender).each do |path|
				value = I18n.t("#{base}.#{path}", default: nil)

				return value if value.present?
			end

			default_label(member)
		end

		private

			#
			# Parse requested localization options.
			#
			def parse_label_options(*options)
				style =
					options & TEXT_VARIANTS.keys

				raise ArgumentError,
							"Multiple text styles specified." if style.size > 1

				style = style.first || :label

				form =
					options & GRAMMATICAL_FORMS

				raise ArgumentError,
							"Multiple grammatical forms specified." if form.size > 1

				form = form.first || :single

				gender =
					options & GRAMMATICAL_GENDERS

				raise ArgumentError,
							"Multiple grammatical genders specified." if gender.size > 1

				gender = gender.first || :neutral

				unknown =
					options -
					TEXT_VARIANTS.keys -
					GRAMMATICAL_FORMS -
					GRAMMATICAL_GENDERS

				unless unknown.empty?
					raise ArgumentError,
								"Unknown localization options: #{unknown.join(', ')}"
				end

				[ style, form, gender ]
			end

			#
			# Build lookup sequence.
			#
			def build_lookup_chain(style, form, gender)
				chain = []

				current = style

				while current

					lookup = TEXT_VARIANTS.fetch(current)[:lookup]

					#
					# Most specific
					#
					chain << "#{lookup}.#{form}.#{gender}"

					#
					# Without gender
					#
					chain << "#{lookup}.#{form}"

					#
					# Plain
					#
					chain << lookup.to_s

					current = TEXT_VARIANTS.fetch(current)[:fallback]

				end

				chain.uniq
			end

			#
			# Last-resort fallback.
			#
			def default_label(member)
				if member
					member.to_s.humanize
				else
					name.demodulize.titleize
				end
			end
	end
end
