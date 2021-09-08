class CreateJoinTableTeamCoach < ActiveRecord::Migration[6.1]
  def change
    create_join_table :teams, :coaches do |t|
      # t.index [:team_id, :coach_id]
      # t.index [:coach_id, :team_id]
    end
  end
end
