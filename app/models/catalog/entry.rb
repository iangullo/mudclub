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
# Catalog::Entry
#
# Immutable entry belonging to a Catalog.
#
# Entries expose the metadata associated with a catalog key and provide
# object-oriented access to it.
#
class Catalog::Entry
	include Comparable

	attr_reader :catalog, :key

	def initialize(catalog:, key:, attributes:)
		@catalog = catalog
		@key = key.to_sym
		@metadata = attributes.deep_symbolize_keys.freeze

		define_attribute_readers

		freeze
	end

	def id
		@metadata[:id]
	end

	def metadata
		@metadata
	end

	alias to_h metadata

	def [](attribute)
		@metadata[attribute.to_sym]
	end

	def fetch(attribute)
		@metadata.fetch(attribute.to_sym)
	end

	def include?(attribute)
		@metadata.key?(attribute.to_sym)
	end

	def <=>(other)
		id <=> other.id
	end

	def inspect
		"#<#{self.class.name} #{catalog.name.demodulize}[#{key}]>"
	end

	def ==(other)
		other.is_a?(self.class) &&
			catalog == other.catalog &&
			key == other.key
	end

	alias eql? ==

	def hash
		[ catalog, key ].hash
	end

	private

		def define_attribute_readers
			@metadata.each_key do |attribute|
				define_singleton_method(attribute) do
					@metadata[attribute]
				end
			end
		end
end
