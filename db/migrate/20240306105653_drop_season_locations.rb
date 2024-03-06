class DropSeasonLocations < ActiveRecord::Migration[7.0]
  def change
    drop_table :season_locations
  end
end
