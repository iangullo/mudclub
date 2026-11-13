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
# app/models/concerns/kinded.rb
#
# Shared interface for models whose `kind` column is backed by a Catalog.
#
# The catalog is derived by convention: Document → Catalog::DocumentKinds.
# Override by defining KIND_CATALOG on the model before including Kinded:
#
#   class SomeModel < ApplicationRecord
#     KIND_CATALOG = Catalog::CustomKinds	# optional
#     include Kinded
#   end
#
module Kinded
	extend ActiveSupport::Concern

	included do
		unless const_defined?(:KIND_CATALOG, false)
			const_set(:KIND_CATALOG, Catalog.const_get("#{name.demodulize}Kinds"))
		end

		catalog_klass   = const_get(:KIND_CATALOG)
		raw_catalog     = catalog_klass.const_get(:CATALOG)

		canonical = {}
		aliases   = {}
		raw_catalog.each do |key, metadata|
			enum_key  = key.to_s.underscore.to_sym
			target_id = metadata[:alias_of] ? raw_catalog.dig(metadata[:alias_of], :id) : metadata[:id]
			next unless target_id

			(metadata[:alias_of] ? aliases : canonical)[enum_key] = target_id
		end

		enum :kind, canonical.merge(aliases), prefix: true

		scope :of_kind, ->(kind) {
			return all if kind.blank?
			keys = Array(kind).map { |k| kind_catalog.resolve(k.to_sym).key }.uniq
			where(kind: keys)
		}
	end

	class_methods do
		def kind_catalog					= const_get(:KIND_CATALOG)
		def kind_list(...)        = kind_catalog.option_list(...)
		def kind_options(...)     = kind_catalog.options(...)

		def kind_image(kind, default: :missing, **rest)
			key    = kind_catalog.normalize(kind)
			symbol = (key && kind_catalog.include?(key)) ? key : default
			{ symbol: }
		end

		def kind_label(kind, ...)
			return if kind.blank?
			kind_catalog.val(kind_catalog.resolve(kind&.to_sym).key, ...)
		end
	end

	# Override in host models (directly or via a concern like PersonBearing) to derive
	# the default gender for this instance's labels. Return :female, :male, or nil.
	# nil → catalog falls back to its :default label.
	def kind
		self.class.kind_catalog.resolve(super&.to_sym)&.key
	end
	def kind_gender     = nil
	def kind_catalog		= self.class.kind_catalog
	def kind_label(...) = self.class.kind_label(kind, ...)
	def kind_list(...)	= self.class.kind_list(...)
	def kind_options(...)     = self.class.kind_catalog.options(...)
	def kind_image(default: :missing, **rest) = self.class.kind_image(kind, default:, **rest)
end
