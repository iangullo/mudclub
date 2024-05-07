class RenameTeamNameAsNick < ActiveRecord::Migration[7.0]
  def change
    rename_column :teams, :name, :nick
  end
end
