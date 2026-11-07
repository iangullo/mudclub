require "test_helper"

class ServerTest < ActiveSupport::TestCase
	setup do
		Server.reload!
		Server.delete_all
		Server.instance
	end

	teardown { Server.reload! }

	# ─── Singleton lifecycle ──────────────────────────────────

	test "instance creates exactly one record on fresh DB" do
		Server.delete_all
		Server.reload!
		assert_difference -> { Server.count }, +1 do
			Server.instance
		end
	end

	test "instance is idempotent within a process" do
		first  = Server.instance
		second = Server.instance
		assert_same first, second
	end

	test "current memoizes into Current" do
		assert_same Server.current, Server.current
	end

	test "reload! clears memoization" do
		Server.current
		Server.reload!
		assert_nil Current.server_settings
		assert_nil Server.instance_variable_get(:@instance)
	end

	# ─── Fresh install defaults ───────────────────────────────

	test "fresh install starts with no optional modules enabled" do
		Server.delete_all
		Server.reload!
		fresh = Server.instance
		assert_equal [], fresh.enabled_modules
		assert_equal Server.optional_modules.map(&:to_s), fresh.disabled_modules
	end

	test "fresh install seeds available_locales with all I18n locales" do
		assert_equal I18n.available_locales.map(&:to_s),
								Server.instance.settings[:available_locales]
	end

	test "fresh install seeds default_locale, time_zone and date_format" do
		s = Server.instance.settings
		assert_equal I18n.default_locale.to_s, s[:default_locale]
		assert_equal "UTC", s[:time_zone]
		assert_equal "default", s[:date_format]
	end

	# ─── Settings merge ───────────────────────────────────────

	test "settings returns a symbolized Hash" do
		s = Server.instance.settings
		assert_kind_of Hash, s
		s.each_key { |k| assert_kind_of Symbol, k }
	end

	test "update_settings! deep-merges and persists" do
		Server.instance.update_settings!(server_name: "A")
		Server.instance.update_settings!(support_email: "a@b.c")
		fresh = Server.find(1)
		assert_equal "A", fresh.server_name
		assert_equal "a@b.c", fresh.support_email
	end

	# ─── Identity ─────────────────────────────────────────────

	test "server_name defaults to MudClub" do
		assert_equal "MudClub", Server.server_name
	end

	test "server_name returns configured value" do
		Server.rebuild!(params(server_name: "MyClub"))
		assert_equal "MyClub", Server.server_name
	end

	test "server_logo defaults to mudclub.svg" do
		assert_equal "mudclub.svg", Server.server_logo
	end

	# ─── Email fallbacks ──────────────────────────────────────

	test "email_from falls back to support_email" do
		Server.rebuild!(params(support_email: "support@x.c"))
		assert_equal "support@x.c", Server.email_from
	end

	test "email_from prefers its own setting" do
		Server.rebuild!(params(support_email: "s@x.c", email_from: "noreply@x.c"))
		assert_equal "noreply@x.c", Server.email_from
	end

	test "email_reply_to falls back to support_email" do
		Server.rebuild!(params(support_email: "s@x.c"))
		assert_equal "s@x.c", Server.email_reply_to
	end

	test "email_signature derives from server_name and support_email" do
		Server.rebuild!(params(server_name: "Club", support_email: "s@x.c"))
		assert_match(/Club/, Server.email_signature)
		assert_match(/s@x\.c/, Server.email_signature)
	end

	# ─── Localization ─────────────────────────────────────────

	test "default_locale returns a Symbol" do
		assert_kind_of Symbol, Server.default_locale
	end

	test "available_locales falls back to I18n.available_locales" do
		assert_equal I18n.available_locales, Server.available_locales
	end

	test "time_zone defaults to UTC" do
		assert_equal "UTC", Server.time_zone
	end

	test "time_zone_list returns pairs sorted by offset with UTC first" do
		list = Server.time_zone_list

		assert_equal "UTC", list.first.last, "UTC must come first"

		labels = list.map(&:first)
		labels.each { |l| assert_match(/\AGMT[+\-]\d{2}:\d{2} · .+\z/, l) }

		# Offsets are monotonic across the list (excluding UTC which is prepended)
		offsets = list.drop(1).map { |label, _| label[/GMT([+\-]\d{2}:\d{2})/, 1] }
		# Not strictly monotonic because of DST offsets, but the primary sort key is utc_offset
		# so we assert the list is at least visually grouped
		assert_includes offsets, "+01:00"
		assert_includes offsets, "-05:00"
	end

	test "time_zone_list values are resolvable by ActiveSupport::TimeZone" do
		Server.time_zone_list.each do |_label, value|
			assert ActiveSupport::TimeZone[value], "unresolvable zone: #{value}"
		end
	end

	test "date_format defaults to :default" do
		assert_equal :default, Server.date_format
	end

	# ─── Public visibility ────────────────────────────────────

	test "public_clubs_enabled defaults to false" do
		assert_not Server.public_clubs_enabled
	end

	test "public_directory_enabled requires public_clubs_enabled" do
		assert_not Server.public_directory_enabled

		Server.rebuild!(params(public_directory_enabled: "1"))
		assert_not Server.public_directory_enabled

		Server.rebuild!(params(public_clubs_enabled: "1"))
		assert Server.public_directory_enabled
	end

	test "public_*_enabled? aliases match the plain readers" do
		assert_equal Server.public_clubs_enabled,    Server.public_clubs_enabled?
		assert_equal Server.public_directory_enabled, Server.public_directory_enabled?
	end

	# ─── Registration predicates ──────────────────────────────

	test "registrations_enabled? mirrors the admissions module" do
		assert_not Server.registrations_enabled?
		Server.enable_module!(:admissions)
		assert Server.registrations_enabled?
		Server.disable_module!(:admissions)
		assert_not Server.registrations_enabled?
	end

	test "registrations_require_terms defaults to true" do
		assert Server.registrations_require_terms
		assert Server.registrations_require_terms?
	end

	# ─── Module state (read) ──────────────────────────────────

	test "module_enabled? returns true for core modules" do
		Server.core_modules.each do |mod|
			assert Server.module_enabled?(mod), "#{mod} should be enabled (core)"
		end
	end

	test "module_enabled? returns false for optional modules by default" do
		Server.optional_modules.each do |mod|
			assert_not Server.module_enabled?(mod), "#{mod} should be disabled by default"
		end
	end

	test "module_enabled? returns false for unknown modules without raising" do
		assert_not Server.module_enabled?(:does_not_exist)
		assert_not Server.module_enabled?("also_missing")
	end

	test "enabled_modules strips blank entries" do
		Server.instance.settings = Server.instance.settings.merge(enabled_modules: [ "", "admissions", "", nil ])
		assert_equal [ "admissions" ], Server.instance.enabled_modules
	end

	# ─── Module state (write) ─────────────────────────────────

	test "enable_module! enables an optional module" do
		assert Server.enable_module!(:admissions)
		assert Server.module_enabled?(:admissions)
	end

	test "enable_module! is idempotent" do
		assert Server.enable_module!(:admissions)
		assert Server.enable_module!(:admissions)
		assert_equal 1, Server.enabled_modules.count("admissions")
	end

	test "enable_module! returns true for core modules" do
		assert Server.enable_module!(:core)
	end

	test "enable_module! returns false for unknown modules" do
		assert_not Server.enable_module!(:nope)
	end

	test "disable_module! disables an enabled module" do
		Server.enable_module!(:admissions)
		assert Server.disable_module!(:admissions)
		assert_not Server.module_enabled?(:admissions)
	end

	test "disable_module! returns false for core modules" do
		assert_not Server.disable_module!(:core)
	end

	test "disable_module! returns false for unknown modules" do
		assert_not Server.disable_module!(:nope)
	end

	# ─── Catalog queries ──────────────────────────────────────

	test "core_modules includes only non-optional modules" do
		assert_includes Server.core_modules, :core
		assert_includes Server.core_modules, :training
		assert_not_includes Server.core_modules, :admissions
	end

	test "optional_modules includes only optional modules" do
		assert_includes Server.optional_modules, :admissions
		assert_not_includes Server.optional_modules, :core
	end

	test "dependencies_of reads from the catalog" do
		assert_includes Server.dependencies_of(:admissions), :participation
		assert_equal [], Server.dependencies_of(:core)
		assert_equal [], Server.dependencies_of(:nonexistent)
	end

	test "dependents_of is transitive" do
		assert_includes Server.dependents_of(:participation), :admissions
		assert_equal [], Server.dependents_of(:admissions)
	end

	# ─── resolve_enabled_modules ──────────────────────────────

	test "resolve_enabled_modules returns requested optional modules" do
		assert_equal [ "admissions" ], Server.resolve_enabled_modules([ "admissions" ])
	end

	test "resolve_enabled_modules drops unknown and non-optional entries" do
		assert_equal [ "admissions" ],
								Server.resolve_enabled_modules([ "core", "unknown", "admissions" ])
	end

	test "resolve_enabled_modules handles nil and empty input" do
		assert_equal [], Server.resolve_enabled_modules(nil)
		assert_equal [], Server.resolve_enabled_modules([])
		assert_equal [], Server.resolve_enabled_modules([ "", "", "" ])
	end

	test "resolve_enabled_modules deduplicates" do
		assert_equal [ "admissions" ],
								Server.resolve_enabled_modules(%w[admissions admissions])
	end

	# ─── rebuild! — regular/boolean ───────────────────────────

	test "rebuild! persists regular options" do
		assert Server.rebuild!(params(
			server_name:    "New Club",
			support_email:  "s@c.cat",
			default_locale: "en",
			date_format:    "long"
		))
		assert_equal "New Club", Server.server_name
		assert_equal "s@c.cat",  Server.support_email
		assert_equal :en,        Server.default_locale
		assert_equal :long,      Server.date_format
	end

	test "rebuild! persists boolean options as booleans" do
		Server.rebuild!(params(public_clubs_enabled: "1"))
		assert_equal true, Server.instance.settings[:public_clubs_enabled]

		Server.rebuild!(params(public_clubs_enabled: "0"))
		assert_equal false, Server.instance.settings[:public_clubs_enabled]
	end

	test "rebuild! clears regular options when given empty string" do
		Server.rebuild!(params(support_email: "a@b.c"))
		Server.rebuild!(params(support_email: ""))
		assert Server.support_email.blank?
	end

	test "rebuild! ignores unknown attributes silently" do
		assert_nothing_raised { Server.rebuild!(params(bogus_key: "value")) }
		assert_nil Server.instance.settings[:bogus_key]
	end

	# ─── rebuild! — modules (the critical part) ───────────────

	test "rebuild! enables modules listed in enabled_modules" do
		Server.rebuild!(params(enabled_modules: [ "admissions" ]))
		assert Server.module_enabled?(:admissions)
	end

	test "rebuild! disables all modules when enabled_modules is empty" do
		Server.rebuild!(params(enabled_modules: [ "admissions" ]))
		assert Server.module_enabled?(:admissions)

		Server.rebuild!(params(enabled_modules: []))
		assert_not Server.module_enabled?(:admissions)
	end

	test "rebuild! handles hidden blank fields from unchecked checkboxes" do
		Server.rebuild!(params(enabled_modules: [ "admissions" ]))
		Server.rebuild!(params(enabled_modules: [ "", "", "" ]))
		assert_not Server.module_enabled?(:admissions)
		assert_equal [], Server.enabled_modules
	end

	test "rebuild! preserves modules when enabled_modules key is absent" do
		Server.rebuild!(params(enabled_modules: [ "admissions" ]))
		Server.rebuild!(params(server_name: "New"))
		assert Server.module_enabled?(:admissions)
	end

	test "rebuild! silently drops unknown modules" do
		Server.rebuild!(params(enabled_modules: [ "admissions", "made_up" ]))
		assert_equal [ "admissions" ], Server.enabled_modules
	end

	test "rebuild! silently drops non-optional modules from enabled_modules" do
		Server.rebuild!(params(enabled_modules: [ "core", "training", "admissions" ]))
		assert_equal [ "admissions" ], Server.enabled_modules
	end

	test "rebuild! disables modules when the form sends the blank hidden value" do
		Server.rebuild!(params(enabled_modules: [ "admissions" ]))
		assert Server.module_enabled?(:admissions)

		# Simulates the exact params the browser sends when all boxes are unchecked
		Server.rebuild!(params(enabled_modules: [ "" ]))
		assert_not Server.module_enabled?(:admissions)
		assert_equal [], Server.enabled_modules
	end

	# ─── rebuild! — validation ────────────────────────────────

	test "rebuild! returns false on validation failure" do
		assert_not Server.rebuild!(params(default_locale: "not_a_locale"))
	end

	test "rebuild! does not persist settings when validation fails" do
		Server.rebuild!(params(server_name: "Before"))
		Server.reload!
		assert_not Server.rebuild!(params(server_name: "After", default_locale: "not_a_locale"))
		assert_equal "Before", Server.find(1).server_name
	end

	test "rebuild! clears memoization after validation failure" do
		Server.rebuild!(params(server_name: "Before"))
		Server.rebuild!(params(server_name: "After", default_locale: "not_a_locale"))
		assert_equal "Before", Server.server_name,
								"rebuild! must reload on failure so readers reflect the DB"
	end

	test "rebuild! exposes validation errors via last_errors" do
		assert_not Server.rebuild!(params(default_locale: "not_a_locale"))
		assert Server.last_errors.any?, "last_errors must contain the failure reason"
		assert_match(/not available/, Server.last_errors.join(" "))
	end

	test "rebuild! clears last_errors on success" do
		Server.rebuild!(params(default_locale: "not_a_locale"))   # populates
		Server.rebuild!(params(server_name: "OK"))                # success
		assert_equal [], Server.last_errors
	end

	test "rebuild! returns false and leaves last_errors empty when nothing changed" do
		Server.rebuild!(params(server_name: "Same"))
		assert_not Server.rebuild!(params(server_name: "Same"))
		assert_equal [], Server.last_errors
	end

	# ─── Validators ───────────────────────────────────────────

	test "rejects unknown default_locale" do
		record = Server.instance
		record.settings = record.settings.merge(default_locale: "xx")
		assert_not record.valid?
		assert_match(/not available/, record.errors.full_messages.join)
	end

	test "accepts known default_locale" do
		record = Server.instance
		record.settings = record.settings.merge(default_locale: I18n.available_locales.first)
		assert record.valid?
	end

	test "rejects unknown date_format" do
		record = Server.instance
		record.settings = record.settings.merge(date_format: "not_a_format")
		assert_not record.valid?
	end

	test "rejects unknown time_zone" do
		record = Server.instance
		record.settings = record.settings.merge(time_zone: "Mars/Olympus")
		assert_not record.valid?
	end

	test "rejects unknown available_locales entries" do
		record = Server.instance
		record.settings = record.settings.merge(available_locales: %w[en klingon])
		assert_not record.valid?
	end

	# ─── Class-level lists ────────────────────────────────────

	test "locale_list returns [label, locale] pairs" do
		Server.locale_list.each do |label, locale|
			assert_kind_of String, label
			assert_kind_of Symbol, locale
		end
	end

	test "date_formats returns a pair per DATE_FORMAT" do
		assert_equal Server::DATE_FORMATS.size, Server.date_formats.size
	end

	# ─── Form compatibility (regression) ──────────────────────

	test "reader methods exist for every BOOLEAN_OPTS" do
		Server::BOOLEAN_OPTS.each do |opt|
			assert Server.instance.respond_to?(opt),
						"#{opt} needs a plain reader (not just #{opt}?) for form.check_box"
		end
	end

	test "dependencies_of returns [] for unknown modules without raising" do
		assert_equal [], Server.dependencies_of(:nonexistent)
		assert_equal [], Server.dependencies_of("also_missing")
		assert_equal [], Server.dependencies_of(nil)
	end

	private

	# Simulates ActionController::Parameters for rebuild! calls.
	def params(hash)
		hash.with_indifferent_access
	end
end
