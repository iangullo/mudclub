class CreateTrainingSlots < ActiveRecord::Migration[6.1]
  def change
    create_table :training_slots do |t|
      t.references :season, null: false, foreign_key: true, default: 0
      t.references :location, null: false, foreign_key: true, default: 0
      t.integer :wday
      t.time :start
      t.integer :duration
      t.references :team, null: false, foreign_key: true, default: 0

      t.timestamps
    end
    TrainingSlot.create(id: 0, wday: 0, start: "16:00", duration: 60)
  end
end
