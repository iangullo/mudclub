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
# Localizable
#
# Provides a common API for localized labels and UI strings.
#
# Classes including this concern must implement:
#
#   translation_scope
#
# and may override:
#
#   translation_values_scope
#
# Example:
#
#   Person.label
#   Person.short
#   Person.label(:name)
#   Person.short(:name)
#
#   Catalog::Modules.label
#   Catalog::Modules.label(:training)
#   Catalog::Modules.short(:training)
#
module Localizable
	# extend ActiveSupport::Concern

	class_methods do
		#
		# Must return the root I18n scope for the class.
		#
		# Examples:
		#
		#   "people.person"
		#   "participation.membership"
		#   "catalog.modules"
		#
		def i18n_scope
			raise NotImplementedError,
						"#{name} must implement .translation_scope"
		end

		#
		# Second-level scope used for members of the class.
		#
		# Models normally use "fields".
		# Catalogs normally use "values".
		#
		def i18n_members_scope
			:fields
		end

		#
		# Class label.
		#
		def label(member = nil)
			translate(:label, member)
		end

		#
		# Short label.
		#
		def short(member = nil)
			translate(:short, member)
		end

		#
		# Optional description.
		#
		def description(member = nil)
			translate(:description, member)
		end

		#
		# Optional placeholder.
		#
		def placeholder(member = nil)
			translate(:placeholder, member)
		end

		#
		# Generic translation lookup.
		#
		def translate(kind, member = nil)
			key =
				if member.nil?
					"#{translation_scope}.#{kind}"
				else
					"#{translation_scope}.#{translation_values_scope}.#{member}.#{kind}"
				end

			I18n.t(
				key,
				default: translation_default(kind, member)
			)
		end

		private

			def translation_default(kind, member)
				return name.demodulize.humanize if member.nil? && kind == :label

				return member.to_s.humanize if member.present? && kind == :label

				if %i[short description placeholder].include?(kind)
					translate(:label, member)
				end
			end
	end
end
