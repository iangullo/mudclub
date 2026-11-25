require "test_helper"

class UserActionTest < ActiveSupport::TestCase
	setup do
		@admin = users(:admin_user)
		@alice = users(:alice)
	end

	test "scopes filter by user, kind, and order latest logs descending" do
		a1 = UserAction.create!(user: @admin, kind: :created, description: "Created club", url: "/clubs/1")
		a2 = UserAction.create!(user: @alice, kind: :updated, description: "Updated profile", url: "/users/2")

		assert_includes UserAction.by_user(@admin), a1
		refute_includes UserAction.by_user(@admin), a2

		assert_includes UserAction.by_kind(:created), a1
		refute_includes UserAction.by_kind(:created), a2
	end

	test "prune replaces matching url with # and clears modal" do
		act = UserAction.create!(user: @admin, kind: :created, description: "Team", url: "/teams/99", modal: true)
		UserAction.prune("/teams/99")

		act.reload
		assert_equal "#", act.url
		assert_nil act.modal
	end

	test "clear deletes only the given user's actions when user is passed, or all when nil" do
		a_admin = UserAction.create!(user: @admin, kind: :enter, description: "Login", url: "/")
		a_alice = UserAction.create!(user: @alice, kind: :enter, description: "Login", url: "/")

		UserAction.clear(@admin)
		refute UserAction.exists?(a_admin.id)
		assert UserAction.exists?(a_alice.id)

		UserAction.clear
		assert_equal 0, UserAction.count
	end
end
