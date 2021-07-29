class CreateTrainingSlots < ActiveRecord::Migration[6.1]
  def change
    create_table :training_slots do |t|
      t.belongs_to :season, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.integer :wday
      t.time :start
      t.integer :duration

      t.timestamps
    end
  end
end
