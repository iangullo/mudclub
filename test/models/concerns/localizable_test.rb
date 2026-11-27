require "test_helper"

class LocalizableTest < ActiveSupport::TestCase
	test "raises NotImplementedError when i18n_scope is not configured" do
		unscoped = Class.new { include Localizable }
		assert_raises(NotImplementedError) { unscoped.i18n_scope }
	end

	test "resolves configured scope and falls back to humanized keys when missing" do
		assert_equal "participation.membership", Membership.i18n_scope
		assert_equal "Nonexistent field", Membership.fld(:nonexistent_field)
		assert_equal "Nonexistent fields", Membership.fld(:nonexistent_field, :plural)
		assert_equal "Nonexistent field hint", Membership.fld(:nonexistent_field, :hint)
	end

	test "instance helpers delegate to class translation methods" do
		member = Membership.new
		assert_equal Membership.label, member.label
		assert_equal Membership.fld(:joined_on), member.fld(:joined_on)
	end
end
