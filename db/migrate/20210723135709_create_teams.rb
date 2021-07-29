class CreateTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.belongs_to :category, null: false, foreign_key: true
      t.belongs_to :division, null: false, foreign_key: true
      t.belongs_to :season, null: false, foreign_key: true

      t.timestamps
    end
  end
end
