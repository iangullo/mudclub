class CreateJoinTableTeamPlayer < ActiveRecord::Migration[6.1]
  def change
    create_join_table :teams, :players do |t|
      # t.index [:team_id, :player_id]
      # t.index [:player_id, :team_id]
    end
  end
end
