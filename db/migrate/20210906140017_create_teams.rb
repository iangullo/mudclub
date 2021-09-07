class CreateTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.references :season
      t.references :category
      t.references :division

      t.timestamps
    end
    add_reference :teams, :homecourt, foreign_key: { to_table: :locations }
  end
end
