require "test_helper"

class AuditableTest < ActiveSupport::TestCase
	test "audit! assigns updated_by without requiring persistence" do
		user   = users(:admin_user)
		member = Membership.new

		assert_nil member.updated_by
		member.audit!(user)
		assert_equal user, member.updated_by
	end
end
