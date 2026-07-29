# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026 Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
# frozen_string_literal: true

#
# Catalog::Entry
#
# Immutable value object representing a single entry of a Catalog.
#
# Entries expose their metadata through dynamically generated readers
# and boolean predicates while delegating all localisation to their
# owning catalog.
#
# frozen_string_literal: true

class Catalog::Entry
	include Comparable

	attr_reader :catalog, :key

	def initialize(catalog:, key:, attributes:)
		@catalog = catalog
		@key = key.to_sym
		@metadata = attributes.deep_symbolize_keys.freeze

		freeze
	end

	#
	# --------------------------------------------------------------------------
	# Metadata
	# --------------------------------------------------------------------------
	#

	def id
		alias? ? catalog.resolve(key).id : @metadata[:id]
	end

	def metadata
		@metadata
	end

	alias to_h metadata

	def [](attribute)
		@metadata[attribute.to_sym]
	end

	def fetch(attribute, default = nil, &block)
		@metadata.fetch(attribute.to_sym, default, &block)
	end

	def key?(attribute)
		@metadata.key?(attribute.to_sym)
	end

	alias include? key?

	#
	# --------------------------------------------------------------------------
	# Localization
	# --------------------------------------------------------------------------
	#

	def label
		catalog.label(key)
	end

	def short
		catalog.short(key)
	end

	def hint
		catalog.hint(key)
	end

	def description
		catalog.description(key)
	end

	#
	# --------------------------------------------------------------------------
	# Helpers
	# --------------------------------------------------------------------------
	#

	def alias?
		include?(:alias_of)
	end

	def canonical?
		!alias?
	end

	def deprecated
		!!self[:deprecated]
	end

	alias deprecated? deprecated

	def aliases
		Array(self[:aliases])
	end

	def tags
		Array(self[:tags])
	end

	def dig(*keys)
		@metadata.dig(*keys)
	end

	#
	# --------------------------------------------------------------------------
	# Comparable
	# --------------------------------------------------------------------------
	#

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
end
