# MudClub - Modular Rails application for managing sports clubs.
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
# app/models/people/person_resolution.rb
class PersonResolution
	attr_reader :status, :person, :people, :conflicts, :matched_by

	# Fields compared when checking a resolved Person against source attrs.
	# Only compared when populated on both sides.
	VERIFIED_FIELDS = %i[name surname birthday dni].freeze

	def initialize(status:, person: nil, people: [], conflicts: {}, matched_by: nil)
		@status     = status
		@person     = person.is_a?(Person) ? person : nil
		@people     = Array(people)
		@conflicts  = conflicts
		@matched_by = matched_by
	end

	#------------------------------------
	# Status accessors
	#------------------------------------
	def ok?
		%i[exact ok].include?(status)
	end

	def exact?
		status == :exact
	end

	def probable?
		status == :probable
	end

	def ambiguous?
		%i[ambiguous probable].include?(status)
	end

	def conflict?
		status == :conflict
	end

	def none?
		status == :none
	end

	def missing?
		status == :missing
	end

	def candidates
		people.presence || Array(person)
	end

	#------------------------------------
	# Validating checks
	#------------------------------------
	# Field names where the resolved person disagrees with `attrs`.
	# Comparison tolerates case, surrounding whitespace, and diacritics —
	# mirrors the DB-level `unaccent` extension in Ruby.
	def mismatches_against(attrs) = self.class.mismatches_against(attrs, person)
	def matches?(attrs)           = mismatches_against(attrs).empty?
	def clean?                    = conflicts.empty?

	def self.mismatches_against(attrs, person)
		return [] unless person

		VERIFIED_FIELDS.select do |field|
			given = attrs[field]
			have  = person.public_send(field)
			next false if given.blank? || have.blank?

			normalize(given) != normalize(have)
		end
	end

	private

		def self.normalize(value)
			return value.to_date.iso8601 if value.respond_to?(:to_date)

			I18n.transliterate(value.to_s).strip.downcase.squeeze(" ")
		end
end
