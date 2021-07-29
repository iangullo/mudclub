class CreateExercises < ActiveRecord::Migration[6.1]
  def change
    create_table :exercises do |t|
      t.belongs_to :training_session, null: false, foreign_key: true
      t.integer :order
      t.references :drill, null: false, foreign_key: true
      t.integer :duration

      t.timestamps
    end
  end
end
