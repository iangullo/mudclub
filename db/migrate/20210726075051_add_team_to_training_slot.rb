class AddTeamToTrainingSlot < ActiveRecord::Migration[6.1]
  def change
    add_reference :training_slots, :team, foreign_key: true, default: 0
  end
end
