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

		enum :kind, const_get(:KIND_CATALOG).enum, prefix: true

		scope :of_kind, ->(kind) {
			return all if kind.blank?
			where(kind: Array(kind).map(&:to_sym))
		}
	end

	class_methods do
		def kind_catalog					= const_get(:KIND_CATALOG)
		def kind_label(kind, ...) = kind_catalog.val(kind.to_sym, ...)
		def kind_image(kind, default: :missing, **rest) = kind_catalog.normalize(kind.to_sym, **rest) || default
		def kind_list(...)        = kind_catalog.option_list(...)
	end

	def kind_catalog		= self.class.kind_catalog
	def kind_image(default: :missing, **rest) = self.class.kind_image(kind, default:, **rest)
	def kind_label(...) = self.class.kind_label(kind, ...)
	def kind_list		    = self.class.kind_list
end
