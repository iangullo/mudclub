class CreateTasks < ActiveRecord::Migration[6.1]
  def change
    create_table :tasks do |t|
      t.belongs_to :event, null: false, foreign_key: true
      t.integer :order
      t.references :drill, null: false, foreign_key: true
      t.integer :duration

      t.timestamps
    end
  end
end
