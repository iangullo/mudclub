require "application_system_test_case"

class SlotsTest < ApplicationSystemTestCase
  setup do
    @slot = slots(:one)
  end

  test "visiting the index" do
    visit slots_url
    assert_selector "h1", text: "Training Slots"
  end

  test "creating a slot" do
    visit slots_url
    click_on "New Slot"

    fill_in "Duration", with: @slot.duration
    fill_in "Location", with: @slot.location_id
    fill_in "Start", with: @slot.start
    fill_in "Team", with: @slot.team_id
    fill_in "Wday", with: @slot.wday
    click_on "Create Training slot"

    assert_text "Training slot was successfully created"
    click_on "Back"
  end

  test "updating a Training slot" do
    visit slots_url
    click_on "Edit", match: :first

    fill_in "Duration", with: @slot.duration
    fill_in "Location", with: @slot.location_id
    fill_in "Season", with: @slot.season_id
    fill_in "Start", with: @slot.start
    fill_in "Team", with: @slot.team_id
    fill_in "Wday", with: @slot.wday
    click_on "Update Training slot"

    assert_text "Training slot was successfully updated"
    click_on "Back"
  end

  test "destroying a Training slot" do
    visit slots_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Training slot was successfully destroyed"
  end
end
