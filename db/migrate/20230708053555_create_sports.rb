class CreateSports < ActiveRecord::Migration[7.0]
  create_table :sports do |t|
    t.string :name
    t.jsonb :settings, default: {}

    t.timestamps
  end
  sport = Sport.new(name: "basketball")
  bball = sport.specific
  bball.save
  add_reference :teams, :sport, foreign_key: true, default: bball.id
  add_reference :categories, :sport, foreign_key: true, default: bball.id
  add_reference :divisions, :sport, foreign_key: true, default: bball.id
end
