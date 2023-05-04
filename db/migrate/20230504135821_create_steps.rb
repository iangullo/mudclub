class CreateSteps < ActiveRecord::Migration[7.0]
  def change
    create_table :steps do |t|
      t.belongs_to :drill, null: false, foreign_key: true
      t.integer :order

      t.timestamps
    end
  end
end
