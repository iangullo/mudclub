require "test_helper"

class HasModulesTest < ActiveSupport::TestCase
	# Isolated host class using the `clubs` table so HasModules is tested
	# without Club's parent-gate overrides or Server's singleton table.
	class DummyHost < ApplicationRecord
		self.table_name = "clubs"
		include HasSettings
		include HasModules
	end

	setup do
		@host = DummyHost.find(clubs(:test_club).id)
		@host.update_columns(settings: {})
	end

	test "raises if included in a class without settings reader" do
		assert_raises(RuntimeError) do
			Class.new do
				include ActiveModel::Validations
				include HasModules
			end
		end
	end

	test "core modules are always enabled while optional modules default to disabled" do
		core_mod = DummyHost.core_modules.first
		opt_mod  = DummyHost.optional_modules.first

		assert @host.module_enabled?(core_mod) if core_mod
		refute @host.module_enabled?(opt_mod)  if opt_mod
		refute @host.module_enabled?(:non_existent_module)
	end

	test "enable_module! enables optional module and resolves transitive dependencies" do
		target = DummyHost.optional_modules.find { |m| DummyHost.dependencies_of(m).any? } || DummyHost.optional_modules.first
		skip "No optional modules defined in Catalog::Modules" unless target

		assert @host.enable_module!(target)
		assert @host.reload.module_enabled?(target)

		DummyHost.dependencies_of(target).each do |dep|
			assert @host.module_enabled?(dep), "dependency #{dep} must be enabled automatically"
		end
	end

	test "disable_module! disables module and cascades to dependents" do
		parent = DummyHost.optional_modules.find { |m| DummyHost.dependents_of(m).any? }
		skip "No module dependency chain in Catalog::Modules" unless parent

		dependent = DummyHost.dependents_of(parent).first
		@host.enable_module!(dependent)
		assert @host.module_enabled?(parent)
		assert @host.module_enabled?(dependent)

		assert @host.disable_module!(parent)
		refute @host.reload.module_enabled?(parent)
		refute @host.module_enabled?(dependent), "dependent #{dependent} must cascade-disable"
	end

	test "validates unknown modules, non-optional modules, and unmet dependencies" do
		@host.settings = { enabled_modules: [ "unknown_xyz" ] }
		refute @host.valid?
		assert_includes @host.errors[:base], "unknown module: unknown_xyz"

		if (core_mod = DummyHost.core_modules.first)
			@host.settings = { enabled_modules: [ core_mod.to_s ] }
			refute @host.valid?
			assert_includes @host.errors[:base], "cannot enable non-optional module: #{core_mod}"
		end

		child = DummyHost.optional_modules.find do |m|
			DummyHost.dependencies_of(m).any? { |d| DummyHost.optional_modules.include?(d) }
		end
		if child
			dep = DummyHost.dependencies_of(child).find { |d| DummyHost.optional_modules.include?(d) }
			@host.settings = { enabled_modules: [ child.to_s ] }
			refute @host.valid?
			assert_includes @host.errors[:base], "module '#{child}' requires '#{dep}'"
		end
	end
end
