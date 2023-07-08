class CreateSports < ActiveRecord::Migration[7.0]
  create_table :sports do |t|
    t.string :name
    t.jsonb :settings, default: {}

    t.timestamps
  end
  add_reference :teams, :sport, foreign_key: true, optional: :true
  add_reference :categories, :sport, foreign_key: true, optional: :true
  add_reference :divisions, :sport, foreign_key: true, optional: :true
end
