# test/services/infrastructure_test.rb
require "test_helper"

class InfrastructureTest < ActiveSupport::TestCase
	# ─── Framework ────────────────────────────────────────────

	test "available? returns true for unknown capabilities" do
		assert Infrastructure.available?(:does_not_exist)
		assert Infrastructure.available?(:also_missing)
	end

	test "available? accepts both strings and symbols" do
		with_stub(Rails.application.config, :cache_store, :memory_store) do
			assert_not Infrastructure.available?("persistent_cache")
			assert_not Infrastructure.available?(:persistent_cache)
		end
	end

	test "every CAPABILITIES entry maps to a defined method" do
		Infrastructure::CAPABILITIES.each do |cap, method_name|
			assert Infrastructure.respond_to?(method_name, true),
						"CAPABILITIES[:#{cap}] -> ##{method_name} is undefined"
		end
	end

	test "diagnostics lists every capability with a boolean value" do
		result = Infrastructure.diagnostics
		assert_equal Infrastructure::CAPABILITIES.keys.sort, result.keys.sort
		result.each do |cap, value|
			assert_includes [ true, false ], value,
											"diagnostics[:#{cap}] returned #{value.inspect}"
		end
	end

	# ─── Database ─────────────────────────────────────────────

	test "postgresql? is true only for postgresql adapter" do
		[ [ "postgresql", true ], [ "mysql2", false ], [ "sqlite3", false ] ].each do |adapter, expected|
			with_stub(ActiveRecord::Base, :connection_db_config, db_config(adapter:)) do
				assert_equal expected, Infrastructure.available?(:postgresql),
										"adapter=#{adapter.inspect}"
			end
		end
	end

	test "database_writable? mirrors replica flag" do
		[ [ false, true ], [ true, false ] ].each do |replica, expected|
			with_stub(ActiveRecord::Base, :connection_db_config, db_config(adapter: "postgresql", replica:)) do
				assert_equal expected, Infrastructure.available?(:database_writable),
										"replica=#{replica.inspect}"
			end
		end
	end

	test "full_text_search? mirrors postgresql?" do
		[ [ "postgresql", true ], [ "mysql2", false ] ].each do |adapter, expected|
			with_stub(ActiveRecord::Base, :connection_db_config, db_config(adapter:)) do
				assert_equal expected, Infrastructure.available?(:full_text_search),
										"adapter=#{adapter.inspect}"
			end
		end
	end

	# ─── Cache ────────────────────────────────────────────────

	test "persistent_cache? is true for durable stores" do
		[ :solid_cache_store, :file_store ].each do |store|
			with_stub(Rails.application.config, :cache_store, store) do
				assert Infrastructure.available?(:persistent_cache),
							"store=#{store.inspect}"
			end
		end
	end

	test "persistent_cache? is false for ephemeral stores" do
		[ :memory_store, :null_store ].each do |store|
			with_stub(Rails.application.config, :cache_store, store) do
				assert_not Infrastructure.available?(:persistent_cache),
									"store=#{store.inspect}"
			end
		end
	end

	test "persistent_cache? is false when cache_store is nil" do
		with_stub(Rails.application.config, :cache_store, nil) do
			assert_not Infrastructure.available?(:persistent_cache)
		end
	end

	test "persistent_cache? accepts array-form cache_store" do
		with_stub(Rails.application.config, :cache_store, [ :solid_cache_store, {} ]) do
			assert Infrastructure.available?(:persistent_cache)
		end
	end

	# ─── Background jobs ──────────────────────────────────────

	test "background_jobs? is true for solid_queue" do
		with_stub(Rails.application.config.active_job, :queue_adapter, :solid_queue) do
			assert Infrastructure.available?(:background_jobs)
		end
	end

	test "background_jobs? is false for inline, async and nil" do
		[ :inline, :async, nil ].each do |adapter|
			with_stub(Rails.application.config.active_job, :queue_adapter, adapter) do
				assert_not Infrastructure.available?(:background_jobs),
									"adapter=#{adapter.inspect}"
			end
		end
	end

	# ─── Solid Stack ──────────────────────────────────────────

	test "solid_stack? requires both solid_cache and solid_queue" do
		[
			[ :solid_cache_store, :solid_queue, true  ],
			[ :solid_cache_store, :async,       false ],
			[ :memory_store,      :solid_queue, false ],
			[ nil,                nil,          false ]
		].each do |cache, queue, expected|
			with_stub(Rails.application.config, :cache_store, cache) do
				with_stub(Rails.application.config.active_job, :queue_adapter, queue) do
					assert_equal expected, Infrastructure.available?(:solid_stack),
											"cache=#{cache.inspect} queue=#{queue.inspect}"
				end
			end
		end
	end

	# ─── Active Storage ───────────────────────────────────────

	test "active_storage? is false for :test, true for :local" do
		[ [ :test, false ], [ :local, true ] ].each do |service, expected|
			with_stub(Rails.application.config.active_storage, :service, service) do
				assert_equal expected, Infrastructure.available?(:active_storage),
										"service=#{service.inspect}"
			end
		end
	end

	test "active_storage? is false when service is nil" do
		with_stub(Rails.application.config.active_storage, :service, nil) do
			assert_not Infrastructure.available?(:active_storage)
		end
	end

	test "persistent_storage? is false for :local, true for :amazon" do
		[ [ :local, false ], [ :amazon, true ] ].each do |service, expected|
			with_stub(Rails.application.config.active_storage, :service, service) do
				assert_equal expected, Infrastructure.available?(:persistent_storage),
										"service=#{service.inspect}"
			end
		end
	end

	# ─── Email ────────────────────────────────────────────────

	test "smtp_configured? requires delivery_method :smtp" do
		with_stub(Rails.application.config.action_mailer, :delivery_method, :test) do
			assert_not Infrastructure.available?(:smtp_configured)
		end
	end

	test "smtp_configured? requires both address and port" do
		with_stub(Rails.application.config.action_mailer, :delivery_method, :smtp) do
			[
				[ { address: "smtp.x.com", port: 587 }, true  ],
				[ { address: "smtp.x.com" },            false ],
				[ { port: 587 },                        false ],
				[ nil,                                  false ]
			].each do |settings, expected|
				with_stub(Rails.application.config.action_mailer, :smtp_settings, settings) do
					assert_equal expected, Infrastructure.available?(:smtp_configured),
											"settings=#{settings.inspect}"
				end
			end
		end
	end

	test "mail_deliverable? is false for dev-side delivery methods" do
		[ :test, :logger, :file, :letter_opener ].each do |method|
			with_stub(Rails.application.config.action_mailer, :delivery_method, method) do
				assert_not Infrastructure.available?(:mail_deliverable),
									"method=#{method.inspect}"
			end
		end
	end

	test "mail_deliverable? is true for real delivery methods" do
		[ :smtp, :sendmail ].each do |method|
			with_stub(Rails.application.config.action_mailer, :delivery_method, method) do
				assert Infrastructure.available?(:mail_deliverable),
							"method=#{method.inspect}"
			end
		end
	end

	# ─── ActionCable ──────────────────────────────────────────

	test "action_cable? is true for a non-test adapter" do
		with_stub(ActionCable.server, :config, cable_config("async")) do
			assert Infrastructure.available?(:action_cable)
		end
	end

	test "action_cable? is false for :test adapter" do
		with_stub(ActionCable.server, :config, cable_config("test")) do
			assert_not Infrastructure.available?(:action_cable)
		end
	end

	test "action_cable? is false when no cable config exists" do
		with_stub(ActionCable.server, :config, cable_config(nil)) do
			assert_not Infrastructure.available?(:action_cable)
		end
	end

	# ─── Image processing ─────────────────────────────────────

	test "image_processing? returns a boolean, never a constant string" do
		result = Infrastructure.available?(:image_processing)
		assert_includes [ true, false ], result,
										"image_processing? returned #{result.inspect}"
	end

	private

	def db_config(adapter:, replica: false)
		obj = Object.new
		obj.define_singleton_method(:adapter)  { adapter }
		obj.define_singleton_method(:replica?) { replica }
		obj
	end

	def cable_config(adapter)
		obj = Object.new
		obj.define_singleton_method(:cable) { adapter ? { adapter: adapter } : nil }
		obj
	end
end
