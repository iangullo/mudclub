class CreateTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.references :season, null: false, foreign_key: true, default: 0
      t.references :category, null: false, foreign_key: true, default: 0
      t.references :division, null: false, foreign_key: true, default: 0

      t.timestamps
    end
    add_reference :teams, :homecourt, foreign_key: { to_table: :locations }, default: 0
    Team.create(id: 0, name: "No Team")
 end
end
