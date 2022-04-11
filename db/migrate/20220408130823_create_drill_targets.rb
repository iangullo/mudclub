class CreateDrillTargets < ActiveRecord::Migration[6.1]
  def change
    create_table :drill_targets do |t|
      t.integer :priority
      t.belongs_to :target, null: false, foreign_key: true
      t.belongs_to :drill, null: false, foreign_key: true

      t.timestamps
    end
  end
end
