require "test_helper"

class CoachesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @coach = coaches(:one)
  end

  test "should get index" do
    get coaches_url
    assert_response :success
  end

  test "should get new" do
    get new_coach_url
    assert_response :success
  end

  test "should create coach" do
    assert_difference('Coach.count') do
      post coaches_url, params: { coach: { active: @coach.active, person_id: @coach.person_id } }
    end

    assert_redirected_to coach_url(Coach.last)
  end

  test "should show coach" do
    get coach_url(@coach)
    assert_response :success
  end

  test "should get edit" do
    get edit_coach_url(@coach)
    assert_response :success
  end

  test "should update coach" do
    patch coach_url(@coach), params: { coach: { active: @coach.active, person_id: @coach.person_id } }
    assert_redirected_to coach_url(@coach)
  end

  test "should destroy coach" do
    assert_difference('Coach.count', -1) do
      delete coach_url(@coach)
    end

    assert_redirected_to coaches_url
  end
end
