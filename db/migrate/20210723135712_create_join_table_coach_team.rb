class CreateJoinTableCoachTeam < ActiveRecord::Migration[6.1]
  def change
    create_join_table :coaches, :teams do |t|
      # t.index [:coach_id, :team_id]
      # t.index [:team_id, :coach_id]
    end
  end
end
