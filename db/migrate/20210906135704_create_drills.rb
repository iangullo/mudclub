class CreateDrills < ActiveRecord::Migration[6.1]
  def change
    create_table :drills do |t|
      t.string :name
      t.string :description
      t.string :material
      t.references :coach, null: false, foreign_key: true, default: 0
      t.references :kind, null: false, foreign_key: true

      t.timestamps
    end
  end
end
