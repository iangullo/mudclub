class AddRulesToTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :rules, :integer, default: 0
  end
end
