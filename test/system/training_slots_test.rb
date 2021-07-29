require "application_system_test_case"

class TrainingSlotsTest < ApplicationSystemTestCase
  setup do
    @training_slot = training_slots(:one)
  end

  test "visiting the index" do
    visit training_slots_url
    assert_selector "h1", text: "Training Slots"
  end

  test "creating a Training slot" do
    visit training_slots_url
    click_on "New Training Slot"

    fill_in "Duration", with: @training_slot.duration
    fill_in "Location", with: @training_slot.location_id
    fill_in "Season", with: @training_slot.season_id
    fill_in "Start", with: @training_slot.start
    fill_in "Wday", with: @training_slot.wday
    click_on "Create Training slot"

    assert_text "Training slot was successfully created"
    click_on "Back"
  end

  test "updating a Training slot" do
    visit training_slots_url
    click_on "Edit", match: :first

    fill_in "Duration", with: @training_slot.duration
    fill_in "Location", with: @training_slot.location_id
    fill_in "Season", with: @training_slot.season_id
    fill_in "Start", with: @training_slot.start
    fill_in "Wday", with: @training_slot.wday
    click_on "Update Training slot"

    assert_text "Training slot was successfully updated"
    click_on "Back"
  end

  test "destroying a Training slot" do
    visit training_slots_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Training slot was successfully destroyed"
  end
end
