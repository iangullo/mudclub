require "test_helper"

class LocationTest < ActiveSupport::TestCase
	test "to_s returns localized none for id 0 and name otherwise" do
		placeholder = Location.new(id: 0, name: "None")
		real_court  = Location.new(id: 99, name: "Pabellón Municipal")

		assert_equal I18n.t("location.none"), placeholder.to_s
		assert_equal "Pabellón Municipal", real_court.to_s
	end

	test "scopes separate practice courts from home courts and exclude placeholder id 0" do
		practice = Location.create!(name: "Pista Entreno", practice_court: true)
		home     = Location.create!(name: "Pabellón Central", practice_court: false)

		assert_includes Location.practice, practice
		refute_includes Location.practice, home

		assert_includes Location.home, home
		refute_includes Location.home, practice
	end

	test "rebuild populates attributes and exists? matches single existing location by name" do
		existing = Location.create!(name: "Polideportivo Sur", practice_court: false)

		loc = Location.new
		loc.rebuild(name: "Polideportivo Sur", gmaps_url: "https://example.com", practice_court: "1")

		assert_equal existing.id, loc.id
		assert_equal "https://example.com", loc.gmaps_url
		assert loc.practice_court?
	end

	test "destroy unlinks dependent events and teams to dummy location 0 and prunes UserActions" do
		Location.find_or_create_by!(id: 0) { |l| l.name = "None" }
		loc    = Location.create!(name: "Pista Temporal", practice_court: false)
		team   = teams(:senior_a)
		team.update_column(:homecourt_id, loc.id)
		event  = Event.create!(club: team.club, team:, kind: :training, location: loc, start_time: 1.day.from_now)
		action = UserAction.create!(user: users(:admin_user), kind: :updated, description: "Edited court", url: "/locations/#{loc.id}")

		loc.destroy!

		assert_equal 0, event.reload.location_id
		assert_equal 0, team.reload.homecourt_id
		assert_equal "#", action.reload.url
	end
end
