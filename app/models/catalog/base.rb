# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026 Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# frozen_string_literal: true

#
# Catalog::Base
#
# Base class for all immutable MudClub catalogs.
#
# Catalogs expose immutable Catalog::Entry objects together with querying,
# localisation and Rails enum compatibility.
#
# frozen_string_literal: true

class Catalog::Base
	include Enumerable
	include Localizable

	class << self
		#
		# ------------------------------------------------------------------------
		# Repository
		# ------------------------------------------------------------------------
		#
		def domain(scope)
			@domain = scope
		end

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

		def keys
			ensure_built!
			@keys
		end

		def values
			ensure_built!
			@values
		end

		def first
			ensure_built!
			@values.first
		end

		def last
			ensure_built!
			@values.last
		end

		# --------------------------------------------------------------------------
		# Normalize an external value into a canonical catalog key.
		# --------------------------------------------------------------------------
		#
		# Examples
		#
		#   normalize(:athlete)         # => :athlete
		#   normalize("athletes")       # => :athlete
		#   normalize("Board Members")  # => :board_member
		#   normalize(nil)              # => nil
		#
		def normalize(value)
			value
				&.to_s
				&.parameterize(separator: "_")
				&.singularize
				&.to_sym
		end

		#
		# Rails enum compatibility.
		#
		def enum
			ensure_built!
			@enum
		end

		#
		# Reverse lookup.
		#
		def entry(id)
			ensure_built!
			@entries_by_id.fetch(id)
		end

		def key(id)
			ensure_built!
			@keys_by_id.fetch(id)
		end

		def id(key)
			resolve(key).id
		end

		#
		# ------------------------------------------------------------------------
		# Lookup
		# ------------------------------------------------------------------------
		#

		def [](key)
			fetch(key)
		end

		def fetch(key)
			ensure_built!
			@entries.fetch(normalize(key))
		end

		def include?(key)
			ensure_built!
			@entries.key?(normalize(key))
		end

		#
		# Returns the canonical entry.
		#
		def resolve(key)
			entry = fetch(key)

			entry = fetch(entry.alias_of) while entry.alias?

			entry
		end

		#
		# Enumerable
		#
		def each(&block)
			ensure_built!
			@values.each(&block)
		end

		#
		# ------------------------------------------------------------------------
		# Queries
		# ------------------------------------------------------------------------
		#

		def where(include_deprecated: false, **criteria)
			ensure_built!

			criteria[:deprecated] = false unless include_deprecated

			@values.select do |entry|
				criteria.all? do |attribute, expected|
					matches_attribute?(
						entry.public_send(attribute),
						expected
					)
				end
			end
		end

		def canonical(...)
			where(...).select(&:canonical?)
		end

		def find_by(...)
			where(...).first
		end

		def options(...)
			canonical(...).map do |entry|
				[ entry.label, entry.id ]
			end
		end

		def selectable
			entries.filter_map do |key, cfg|
				key if cfg.fetch(:selectable, false)
			end
		end

		#
		# ------------------------------------------------------------------------
		# Localizable
		# ------------------------------------------------------------------------
		#

		def i18n_scope
			@i18n_scope ||= "#{@domain}.#{name.demodulize.underscore}"
		end

		def i18n_members_scope
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
								attributes: metadata.deep_dup
							)
					end.freeze

				@keys = @entries.keys.freeze

				@values =
					@entries.values.sort.freeze

				@enum =
					@entries
						.reject { |_k, e| e.alias? }
						.transform_values(&:id)
						.freeze

				@entries_by_id =
					@entries
						.reject { |_k, e| e.alias? }
						.each_with_object({}) do |(_, entry), hash|
							hash[entry.id] = entry
						end
						.freeze

				@keys_by_id =
					@entries
						.reject { |_k, e| e.alias? }
						.each_with_object({}) do |(key, entry), hash|
							raise ArgumentError,
										"Duplicate catalog id #{entry.id}" if hash.key?(entry.id)

							hash[entry.id] = key
						end
						.freeze
			end

			def matches_attribute?(actual, expected)
				if expected.is_a?(Array)
					expected.include?(actual)

				elsif actual.is_a?(Array)
					Array(expected).all? do |value|
						actual.include?(value)
					end

				else
					actual == expected
				end
			end
	end
end
