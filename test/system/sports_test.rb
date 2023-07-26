require "application_system_test_case"

class SportsTest < ApplicationSystemTestCase
  setup do
    @sport = sports(:one)
  end

  test "visiting the index" do
    visit sports_url
    assert_selector "h1", text: "Sports"
  end

  test "should create sport" do
    visit sports_url
    click_on "New sport"

    click_on "Create Sport"

    assert_text "Sport was successfully created"
    click_on "Back"
  end

  test "should update Sport" do
    visit sport_url(@sport)
    click_on "Edit this sport", match: :first

    click_on "Update Sport"

    assert_text "Sport was successfully updated"
    click_on "Back"
  end

  test "should destroy Sport" do
    visit sport_url(@sport)
    click_on "Destroy this sport", match: :first

    assert_text "Sport was successfully destroyed"
  end
end
