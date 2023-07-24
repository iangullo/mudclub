class DroprulesFromTeams < ActiveRecord::Migration[7.0]
  def change
    remove_column :teams, :rules
  end
end
