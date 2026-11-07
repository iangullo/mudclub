require "test_helper"

class UserTest < ActiveSupport::TestCase
	# ─── HasSettings integration ─────────────────────────────
	# User includes HasSettings but NOT HasModules. These tests prove the
	# storage contract works on a model with no module layer.

	test "settings are symbol-keyed on read" do
		user = users(:admin_user)
		user.update_columns(settings: { "locale" => "en", "theme" => "dark" })
		assert_equal "en",   user.settings[:locale]
		assert_equal "dark", user.settings[:theme]
		assert_nil user.settings["locale"], "reads must be symbol-keyed"
	end

	test "settings returns {} when column is nil" do
		user = users(:admin_user)
		user.update_columns(settings: nil)
		assert_equal({}, user.settings)
	end

	test "update_settings! persists the merge" do
		user = users(:admin_user)
		user.update_settings!(locale: "en", theme: "dark")
		user.reload
		assert_equal "en",   user.settings[:locale]
		assert_equal "dark", user.settings[:theme]
	end

	test "update_settings! preserves unrelated keys" do
		user = users(:admin_user)
		user.update_settings!(locale: "en")
		user.update_settings!(theme: "dark")
		user.reload
		assert_equal "en",   user.settings[:locale]
		assert_equal "dark", user.settings[:theme]
	end

	# ─── locale accessor (uses set_setting, NOT update_settings!) ──
	# set_setting does `self.settings = settings.merge(...)` — assignment,
	# not persistence. A save is required. This distinction is easy to miss.

	test "locale= writes to in-memory settings but does not persist until save" do
		user = users(:admin_user)
		user.locale = "fr"
		assert_equal "fr", user.settings[:locale], "in-memory write happens immediately"
		refute_equal "fr", User.find(user.id).settings[:locale],
			"locale= must not bypass the save contract"
		user.save!
		assert_equal "fr", user.reload.locale
	end

	test "locale reads nil when unset" do
		user = users(:admin_user)
		user.update_columns(settings: {})
		assert_nil user.reload.locale
	end

	# ─── role / system role ──────────────────────────────────

	test "system_admin? is false for role: user" do
		user = users(:admin_user)
		assert_equal "user", user.role
		refute user.system_admin?
		assert_equal :user, user.system_role
	end

	test "system_admin? is true for role: admin" do
		user = users(:admin_user)
		user.update!(role: :admin)
		assert user.system_admin?
		assert_equal :admin, user.system_role
	end

	# ─── active? (the User override, distinct from active_for_authentication?) ──
	# Note: Devise's active_for_authentication? calls ITS OWN super, not
	# this #active?. These are two different predicates. Test both.

	test "active? is true for system admins regardless of memberships" do
		user = users(:admin_user)
		user.update!(role: :admin)
		assert user.active?
	end

	test "active? is false for non-admin without memberships" do
		user = users(:admin_user)
		assert_equal "user", user.role
		refute user.active?
	end

	test "active? is false after anonymize! even for admins" do
		user = users(:admin_user)
		user.update!(role: :admin)
		user.anonymize!
		refute user.reload.active?
	end

	# ─── anonymize! ──────────────────────────────────────────
	test "anonymize! wipes settings and marks the account" do
		user = users(:admin_user)
		user.update_columns(settings: { "locale" => "en" })
		user.reload
		assert_nil user.anonymized_at

		user.anonymize!
		user.reload

		assert_not_nil user.anonymized_at
		assert_equal({}, user.settings)
		assert_match(/\Aanonymized\+.*@invalid\.local\z/, user.read_attribute(:email),
			"the email column must be anonymized — user.email delegates to person")
	end

	test "anonymize! is idempotent" do
		user = users(:admin_user)
		user.anonymize!
		first = user.reload.anonymized_at
		user.anonymize!
		assert_equal first, user.reload.anonymized_at
	end

	test "active_for_authentication? is false after anonymize!" do
		user = users(:admin_user)
		assert user.active_for_authentication?, "baseline — Devise super returns true"
		user.anonymize!
		refute user.reload.active_for_authentication?
	end

	test "inactive_message is :anonymized after anonymize!" do
		user = users(:admin_user)
		user.anonymize!
		assert_equal :anonymized, user.reload.inactive_message
	end

	# ─── class API ───────────────────────────────────────────

	test "locale_list returns [label, locale] pairs" do
		list = User.locale_list
		assert list.any?
		list.each { |pair| assert_equal 2, pair.size }
	end

	test "role_list is restricted to user and admin" do
		values = User.role_list.map(&:last)
		assert_equal %i[user admin], values
	end

	# ─── search ──────────────────────────────────────────────
	# User.search(user, ...) has a latent bug: if user is nil,
	# `user.admin?` raises. Only pass a user here.

	test "search returns nothing for non-admin" do
		assert_equal 0, User.search("alice", users(:admin_user)).count
	end

	test "search returns real users for admin without search term" do
		admin = users(:admin_user)
		admin.update!(role: :admin)
		result = User.search(nil, admin)
		assert result.count >= 1
		assert result.all? { |u| u.id > 0 }
	end
end
