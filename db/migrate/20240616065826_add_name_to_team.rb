class AddNameToTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :name, :string

    Team.all.each do |team|
      team.name = team.nick
      team.save
    end
  end
end
