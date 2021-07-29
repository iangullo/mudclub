class CreateTrainingSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :training_sessions do |t|
      t.belongs_to :team, null: false, foreign_key: true
      t.date :date
      t.references :training_slot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
