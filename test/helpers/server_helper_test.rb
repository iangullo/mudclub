# test/helpers/server_helper_test.rb
require "test_helper"

class ServerHelperTest < ActiveSupport::TestCase
	setup do
		Server.reload!
		Server.delete_all
		Server.instance
	end

	teardown { Server.reload! }

	# ApplicationController.helpers returns a proxy with ALL helper modules
	# mixed in — including ApplicationHelper, where symbol_item, gap_item,
	# gap_row and label_item live.
	def helpers
		@helpers ||= ApplicationController.helpers
	end

	test "server_edit_accordion returns one entry per configurable section" do
		sections = helpers.server_edit_accordion

		assert_equal 5, sections.size

		expected = %i[contact_section email_section localization_section
									visibility_section modules_section]
		actual = sections.map { |s| s[:head].to_s }

		expected.each do |key|
			assert_includes actual, Server.fld(key),
											"missing section: #{key}"
		end
	end

	test "every accordion entry has a FieldsComponent as content" do
		helpers.server_edit_accordion.each do |section|
			assert_kind_of FieldsComponent, section[:content],
										"section #{section[:head].inspect} has no FieldsComponent content"
		end
	end

	test "accordion content receives the form when one is provided" do
		fake_form = Object.new
		sections  = helpers.server_edit_accordion(form: fake_form)

		sections.each do |section|
			assert_equal fake_form,
									section[:content].instance_variable_get(:@form),
									"form not propagated to #{section[:head].inspect}"
		end
	end

	test "modules section emits a checkbox per optional module" do
		rows   = helpers.send(:server_modules_section)
		values = rows.flat_map do |row|
			row.select { |f| f.is_a?(Hash) && f[:key] == :enabled_modules }
		end.map { |f| f[:value] }

		Server.optional_modules.each do |mod|
			assert_includes values, mod.to_s, "missing checkbox for #{mod}"
		end
	end

	test "modules section always emits the enabled_modules hidden field" do
		rows = helpers.send(:server_modules_section)
		hidden = rows.flat_map { |r| r.select { |f| f.is_a?(Hash) && f[:kind] == :hidden } }.first

		assert hidden, "modules section must emit a hidden field for enabled_modules"
		assert_equal "server[enabled_modules][]", hidden[:name]
		assert_equal "", hidden[:value]
	end

	test "email section uses raw setting as value and support_email as placeholder" do
		Server.rebuild!(ActionController::Parameters.new(support_email: "s@x.c").permit!)

		row   = helpers.send(:server_email_section).find do |r|
			r.any? { |f| f.is_a?(Hash) && f[:key] == :email_from }
		end
		field = row.find { |f| f.is_a?(Hash) && f[:key] == :email_from }

		assert_nil field[:value], "email_from value must be raw, not the fallback"
		assert_equal "s@x.c", field[:placeholder], "placeholder must show the fallback"
	end
end
