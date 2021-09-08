class CreateJoinTableDrillSkill < ActiveRecord::Migration[6.1]
  def change
    create_join_table :drills, :skills do |t|
      # t.index [:drill_id, :skill_id]
      # t.index [:skill_id, :drill_id]
    end
  end
end
