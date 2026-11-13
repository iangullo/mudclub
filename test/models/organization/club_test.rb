# test/models/club_test.rb
require "test_helper"

class ClubTest < ActiveSupport::TestCase
	setup do
		Server.reload!
		Server.instance.update_settings!(
			enabled_modules:      [],
			public_clubs_enabled: false
		)
		@club = clubs(:test_club)
		# Reset module state so tests are independent
		@club.update_settings!(enabled_modules: [])
	end

	teardown do
		Server.reload!
	end

	# ─── Two-tier gate ─────────────────────────────────────

	test "clubs do NOT inherit server modules implicitly" do
		Server.enable_module!(:admissions)
		assert Server.module_enabled?(:admissions)
		refute @club.module_enabled?(:admissions),
			"clubs must opt in explicitly — no implicit inheritance"
	end

	test "module_enabled? requires both server and club gates" do
		# neither
		refute @club.module_enabled?(:admissions)

		# club only — server off, club on
		@club.update_settings!(enabled_modules: [ "admissions" ])
		refute @club.module_enabled?(:admissions),
			"club cannot enable a server-disabled module"

		# both
		Server.enable_module!(:admissions)
		assert @club.module_enabled?(:admissions)

		# server off again — club on but server off
		Server.disable_module!(:admissions)
		refute @club.module_enabled?(:admissions),
			"server gate must override club opt-in at runtime"
	end

	test "resolve_enabled_modules only returns optional modules" do
		result = Club.resolve_enabled_modules([ "admissions" ])

		assert_includes result, "admissions"
		result.each do |mod|
			assert Club.optional_modules.map(&:to_s).include?(mod),
				"resolve_enabled_modules must never return core modules (got #{mod})"
		end
	end

	test "enable_module! is a no-op when server gate is off" do
		Server.disable_module!(:admissions)
		refute @club.enable_module!(:admissions)
		refute_includes @club.enabled_modules, "admissions"
	end

	test "enable_module! resolves the full dependency chain" do
		Server.enable_module!(:admissions)
		@club.enable_module!(:admissions)

		deps = @club.class.dependencies_of(:admissions) || []

		# Optional dependencies get auto-added to enabled_modules
		(deps & @club.class.optional_modules).each do |dep|
			assert_includes @club.enabled_modules, dep.to_s,
				"optional dependency #{dep} should have been auto-enabled"
		end

		# Core dependencies are always available — computed, never persisted
		(deps & @club.class.core_modules).each do |dep|
			assert @club.module_enabled?(dep),
				"core dependency #{dep} should be implicitly enabled"
			refute_includes @club.enabled_modules, dep.to_s,
				"core dependency #{dep} must not pollute enabled_modules"
		end
	end

	# ─── offerable_modules ────────────────────────────────

	test "offerable_modules lists server-enabled modules only" do
		Server.disable_module!(:admissions)
		refute_includes Club.offerable_modules, :admissions

		Server.enable_module!(:admissions)
		assert_includes Club.offerable_modules, :admissions
	end

	test "needs_module_review? is true when the club has not adopted an offerable module" do
		Server.enable_module!(:admissions)
		@club.update_settings!(enabled_modules: [])
		assert @club.needs_module_review?

		@club.enable_module!(:admissions)
		refute @club.needs_module_review?
	end
end
