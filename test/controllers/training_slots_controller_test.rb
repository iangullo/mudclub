require "test_helper"

class TrainingSlotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @training_slot = training_slots(:one)
  end

  test "should get index" do
    get training_slots_url
    assert_response :success
  end

  test "should get new" do
    get new_training_slot_url
    assert_response :success
  end

  test "should create training_slot" do
    assert_difference('TrainingSlot.count') do
      post training_slots_url, params: { training_slot: { duration: @training_slot.duration, location_id: @training_slot.location_id, season_id: @training_slot.season_id, start: @training_slot.start, wday: @training_slot.wday } }
    end

    assert_redirected_to training_slot_url(TrainingSlot.last)
  end

  test "should show training_slot" do
    get training_slot_url(@training_slot)
    assert_response :success
  end

  test "should get edit" do
    get edit_training_slot_url(@training_slot)
    assert_response :success
  end

  test "should update training_slot" do
    patch training_slot_url(@training_slot), params: { training_slot: { duration: @training_slot.duration, location_id: @training_slot.location_id, season_id: @training_slot.season_id, start: @training_slot.start, wday: @training_slot.wday } }
    assert_redirected_to training_slot_url(@training_slot)
  end

  test "should destroy training_slot" do
    assert_difference('TrainingSlot.count', -1) do
      delete training_slot_url(@training_slot)
    end

    assert_redirected_to training_slots_url
  end
end
