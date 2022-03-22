class CreateSeasonLocations < ActiveRecord::Migration[6.1]
  def change
    create_table :season_locations do |t|
      t.belongs_to :season, null: false, foreign_key: true
      t.belongs_to :location, null: false, foreign_key: true

      t.timestamps
    end
  end
end
