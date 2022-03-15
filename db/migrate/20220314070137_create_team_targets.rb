class CreateTeamTargets < ActiveRecord::Migration[6.1]
  def change
    create_table :team_targets do |t|
      t.belongs_to :team, null: false, foreign_key: true
      t.belongs_to :target, null: false, foreign_key: true
      t.integer :priority

      t.timestamps
    end
  end
end
