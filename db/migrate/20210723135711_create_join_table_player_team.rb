class CreateJoinTablePlayerTeam < ActiveRecord::Migration[6.1]
  def change
    create_join_table :players, :teams do |t|
      # t.index [:player_id, :team_id]
      # t.index [:team_id, :player_id]
    end
  end
end
