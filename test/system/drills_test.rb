require "application_system_test_case"

class DrillsTest < ApplicationSystemTestCase
  setup do
    @drill = drills(:one)
  end

  test "visiting the index" do
    visit drills_url
    assert_selector "h1", text: "Drills"
  end

  test "creating a Drill" do
    visit drills_url
    click_on "New Drill"

    fill_in "Coach", with: @drill.coach_id
    fill_in "Description", with: @drill.description
    fill_in "Kind", with: @drill.kind_id
    fill_in "Material", with: @drill.material
    fill_in "Name", with: @drill.name
    click_on "Create Drill"

    assert_text "Drill was successfully created"
    click_on "Back"
  end

  test "updating a Drill" do
    visit drills_url
    click_on "Edit", match: :first

    fill_in "Coach", with: @drill.coach_id
    fill_in "Description", with: @drill.description
    fill_in "Kind", with: @drill.kind_id
    fill_in "Material", with: @drill.material
    fill_in "Name", with: @drill.name
    click_on "Update Drill"

    assert_text "Drill was successfully updated"
    click_on "Back"
  end

  test "destroying a Drill" do
    visit drills_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Drill was successfully destroyed"
  end
end
