class AddHomecourtToTeams < ActiveRecord::Migration[6.1]
  def change
    add_reference :teams, :homecourt, foreign_key: { to_table: :locations }
  end
end
