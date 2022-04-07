class AddMonthToTeamTargets < ActiveRecord::Migration[6.1]
  def change
    add_column :team_targets, :month, :integer
  end
end
