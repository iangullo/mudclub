require "test_helper"

class SportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sport = sports(:one)
  end

  test "should get index" do
    get sports_url
    assert_response :success
  end

  test "should get new" do
    get new_sport_url
    assert_response :success
  end

  test "should create sport" do
    assert_difference("Sport.count") do
      post sports_url, params: { sport: {  } }
    end

    assert_redirected_to sport_url(Sport.last)
  end

  test "should show sport" do
    get sport_url(@sport)
    assert_response :success
  end

  test "should get edit" do
    get edit_sport_url(@sport)
    assert_response :success
  end

  test "should update sport" do
    patch sport_url(@sport), params: { sport: {  } }
    assert_redirected_to sport_url(@sport)
  end

  test "should destroy sport" do
    assert_difference("Sport.count", -1) do
      delete sport_url(@sport)
    end

    assert_redirected_to sports_url
  end
end
