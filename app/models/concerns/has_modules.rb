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
# app/models/concerns/has_modules.rb
#
# Shared interface for models that can be configured with
# optional MudClub modules (Server, Club, …).
#
# Contract expected of the including class:
#   * a `settings` reader returning a Hash
#   * an `update_settings!(attrs)` mutator that persists a merge
#   * a `modules_key` class_attribute (provided below)

module HasModules
	extend ActiveSupport::Concern

	MODULES_KEY = :enabled_modules

	included do
		class_attribute :modules_key, default: MODULES_KEY

		validate :enabled_modules_are_known
		validate :enabled_modules_dependencies_satisfied

		unless method_defined?(:settings) || private_method_defined?(:settings)
			raise "#{name} must define a `settings` reader before including HasModules"
		end
	end

	class_methods do
		# ─── Catalog queries ─────────────────────────────────────
		def core_modules
			@core_modules ||= Catalog::Modules.where(optional: false).map(&:key).freeze
		end

		def optional_modules
			@optional_modules ||= Catalog::Modules.where(optional: true).map(&:key).freeze
		end

		# "What modules could this model enable?"
		# Default: all optional modules. Classes with a parent gate
		# (e.g. Club, gated by Server) override this.
		def offerable_modules
			optional_modules
		end

		def all_modules
			@all_modules ||= Catalog::Modules.keys.freeze
		end

		def dependencies_of(name)
			return [] unless Catalog::Modules.include?(name)
			Array(Catalog::Modules[name]&.dig(:dependencies)).map(&:to_sym)
		end

		def dependents_of(name)
			target = name.to_sym
			seen   = Set.new
			queue  = [ target ]
			until queue.empty?
				current = queue.shift
				Catalog::Modules.keys.each do |k|
					next if seen.include?(k)
					next unless dependencies_of(k).include?(current)
					seen << k
					queue << k
				end
			end
			seen.to_a
		end

		def resolve_enabled_modules(requested)
			requested    = Array(requested).map(&:to_s)
			catalog_keys = optional_modules.map(&:to_s)
			selected     = requested & catalog_keys

			target = Set.new(selected)
			queue  = selected.dup
			until queue.empty?
				current = queue.shift
				dependencies_of(current).each do |dep|
					dep = dep.to_s
					next unless catalog_keys.include?(dep)
					next if target.include?(dep)
					target << dep
					queue  << dep
				end
			end
			target.to_a
		end
	end

	# ─── Instance readers ──────────────────────────────────────
	# Tolerant of string-keyed and symbol-keyed settings during
	# the Club → symbol-key migration.
	def enabled_modules
		raw = settings[modules_key] || settings[modules_key.to_s]
		Array(raw).map(&:to_s).reject(&:blank?)
	end

	def disabled_modules
		self.class.optional_modules.map(&:to_s) - enabled_modules
	end

	def missing_offerable_modules
		self.class.offerable_modules.map(&:to_s) - enabled_modules
	end

	def needs_module_review?
		missing_offerable_modules.any?
	end

	# ─── Predicate ─────────────────────────────────────────────
	# Override in classes that gate on a higher-level enabler
	# (e.g. Club consults Server first).
	def module_enabled?(name)
		return false unless Catalog::Modules.include?(name)
		entry = Catalog::Modules[name]
		return true unless entry[:optional]
		enabled_modules.include?(name.to_s)
	end

	# ─── Mutators ──────────────────────────────────────────────
	def enable_module!(name)
		return false unless Catalog::Modules.include?(name)
		entry = Catalog::Modules[name]
		return true  unless entry[:optional]
		return true  if module_enabled?(name)

		to_enable = self.class.resolve_enabled_modules([ name ])
		update_settings!(modules_key => (enabled_modules | to_enable).uniq)
		true
	end

	def disable_module!(name)
		return false unless Catalog::Modules.include?(name)
		entry = Catalog::Modules[name]
		return false unless entry[:optional]
		return true  unless module_enabled?(name)

		cascade = self.class.dependents_of(name).map(&:to_s)
		update_settings!(modules_key => (enabled_modules - [ name.to_s ] - cascade))
		true
	end

	private

		def enabled_modules_are_known
			enabled_modules.each do |mod|
				unless Catalog::Modules.include?(mod)
					errors.add(:base, "unknown module: #{mod}")
					next
				end
				entry = Catalog::Modules[mod]
				errors.add(:base, "cannot enable non-optional module: #{mod}") unless entry[:optional]
			end
		end

		def enabled_modules_dependencies_satisfied
			enabled_modules.each do |mod|
				next unless Catalog::Modules.include?(mod)
				self.class.dependencies_of(mod).each do |dep|
					next unless Catalog::Modules.include?(dep)
					next unless Catalog::Modules[dep][:optional]
					next if module_enabled?(dep)
					errors.add(:base, "module '#{mod}' requires '#{dep}'")
				end
			end
		end
end
