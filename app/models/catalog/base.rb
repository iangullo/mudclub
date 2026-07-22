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
# Catalog::Base
#
# Base class for immutable application catalogs.
#
# Subclasses define a CATALOG constant containing the metadata for each
# entry. Entries are built lazily and exposed as immutable objects.
#
class Catalog::Base
	include Enumerable
	include Localizable

	class << self
		#
		# Public API
		#

		def size
			ensure_built!
			@entries.size
		end

		def empty?
			size.zero?
		end

		def entries
			ensure_built!
			@entries
		end

		alias definitions entries

		def keys
			ensure_built!
			@keys
		end

		def values
			ensure_built!
			@values
		end

		#
		# Rails enum helper.
		#
		def enum
			ensure_built!
			@enum
		end

		#
		# Reverse lookup.
		#
		def keys_by_id
			ensure_built!
			@keys_by_id
		end

		alias ids keys_by_id

		def [](key)
			fetch(key)
		end

		def fetch(key)
			ensure_built!
			@entries.fetch(key.to_sym)
		end

		def include?(key)
			ensure_built!
			@entries.key?(key.to_sym)
		end

		def id(key)
			fetch(key).id
		end

		def key(id)
			ensure_built!
			@keys_by_id.fetch(id)
		end

		def each(&block)
			ensure_built!
			@entries.each_value(&block)
		end

		def where(**criteria)
			ensure_built!

			@entries.select do |_key, entry|
				criteria.all? do |attribute, expected|
					actual = entry.public_send(attribute)

					if expected.is_a?(Array)
						expected.include?(actual)
					elsif actual.is_a?(Array)
						Array(expected).all? { |value| actual.include?(value) }
					else
						actual == expected
					end
				end
			end
		end

		def find_by(**criteria)
			where(**criteria).values.first
		end

		def matches?(key, **criteria)
			entry = fetch(key)

			criteria.all? do |attribute, expected|
				actual = entry.public_send(attribute)

				if actual.is_a?(Array)
					Array(expected).all? { |value| actual.include?(value) }
				else
					actual == expected
				end
			end
		end


		def self.i18n_scope
			@i18n_scope ||= "catalog.#{name.demodulize.underscore}"
		end

		def self.i18n_members_scope
			:values
		end

		private

			def built?
				defined?(@entries)
			end

			def ensure_built!
				build! unless built?
			end

			def build!
				raw = const_get(:CATALOG)

				@entries =
					raw.each_with_object({}) do |(key, metadata), hash|
						hash[key.to_sym] =
							Catalog::Entry.new(
								catalog: self,
								key: key,
								attributes: metadata
							)
					end.freeze

				@keys = @entries.keys.freeze

				@values = @entries.values.freeze

				@enum =
					@entries.transform_values(&:id).freeze

				@keys_by_id =
					@entries.each_with_object({}) do |(key, entry), hash|
						raise ArgumentError,
							"Duplicate catalog id #{entry.id}" if hash.key?(entry.id)

						hash[entry.id] = key
					end.freeze
			end
	end
end
