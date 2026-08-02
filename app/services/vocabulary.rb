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

# app/services/vocabulary.rb
#
# Vocabulary
#
# Resolves sport terminology with the following precedence:
#
#   1. Club settings override
#   2. Sport locale override
#   3. Canonical core.sport term
#   4. Caller supplied fallback
#   5. Humanized concept
#
# Canonical locale layout:
#
# core:
#   sport:
#     terms:
#       athlete:
#         single:
#         plural:
#         short:
#         hint:
#         description:
#         tooltip:
#
# Sport-specific locales override only what they need:
#
# sport:
#   basketball:
#     terms:
#       athlete:
#         single: Player
#         plural: Players
#
module Vocabulary
	module_function

	# --------------------------------------------------------------------------
	# Public API
	# --------------------------------------------------------------------------

	def term(key,
					form: :single,
					variant: :label,
					override_scope: nil,
					club: nil,
					fallback: nil)
		leaf = resolve_leaf(form:, variant:)

		#
		# 1. Club override
		#
		if club
			value = lookup_club(club, key, leaf)
			return value if value.present?
		end

		#
		# 2. Sport override
		#
		if override_scope.present?
			value = lookup_scope(override_scope, key, leaf)
			return value if value.present?
		end

		#
		# 3. Canonical core vocabulary
		#
		value = lookup_scope("core.sport", key, leaf)
		return value if value.present?

		#
		# 4. Explicit fallback
		#
		case fallback
		when Proc
			value = fallback.call
			return value if value.present?

		when Symbol
			value = I18n.t(fallback, default: nil)
			return value if value.present?

		when String
			return fallback if fallback.present?
		end

		#
		# 5. Humanized concept
		#
		key.to_s.humanize
	end

	# --------------------------------------------------------------------------
	# Helpers
	# --------------------------------------------------------------------------

	def resolve_leaf(form:, variant:)
		case variant
		when :label
			form.to_s

		when :short
			"short"

		when :hint
			"hint"

		when :description
			"description"

		when :tooltip
			"tooltip"

		else
			variant.to_s
		end
	end
	private_class_method :resolve_leaf

	def lookup_scope(scope, key, leaf)
		I18n.t(
			"#{scope}.terms.#{key}.#{leaf}",
			default: nil
		).presence
	end
	private_class_method :lookup_scope

	#
	# Club settings structure:
	#
	# settings:
	#   locales:
	#     participation.membership_kinds.values.club_manager.label: Director Deportivo
	#
	def lookup_club(club, key, leaf)
		return nil unless club.respond_to?(:settings)

		settings =
			club.settings.is_a?(Hash) ?
				club.settings :
				{}

		locales =
			settings["locales"] ||
			settings[:locales] ||
			{}

		locales["core.sport.terms.#{key}.#{leaf}"] ||
			locales[:"core.sport.terms.#{key}.#{leaf}"]
	end
	private_class_method :lookup_club
end
