class CreateSports < ActiveRecord::Migration[7.0]
  create_table :sports do |t|
    t.string :name
    t.jsonb :settings, default: {}

    t.timestamps
  end
  add_reference :teams, :sport, foreign_key: true, optional: :true
  add_reference :categories, :sport, foreign_key: true, optional: :true
  add_reference :divisions, :sport, foreign_key: true, optional: :true
  sport = Sport.new(name: "basketball")
  bball = sport.specific
  bball.save
  Category.real.each {|cat| cat.update! sport_id: bball.id}
  Division.real.each {|div| div.update! sport_id: bball.id}
  Team.real.each {|team| team.update! sport_id: bball.id}
end
