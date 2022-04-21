require "application_system_test_case"

class DivisionsTest < ApplicationSystemTestCase
  setup do
    @division = divisions(:one)
  end

  test "visiting the index" do
    visit divisions_url
    assert_selector "h1", text: "Divisions"
  end

  test "creating a Division" do
    visit divisions_url
    click_on "New Division"

    click_on "Create Division"

    assert_text "Division was successfully created"
    click_on "Back"
  end

  test "updating a Division" do
    visit divisions_url
    click_on "Edit", match: :first

    click_on "Update Division"

    assert_text "Division was successfully updated"
    click_on "Back"
  end

  test "destroying a Division" do
    visit divisions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Division was successfully destroyed"
  end
end
