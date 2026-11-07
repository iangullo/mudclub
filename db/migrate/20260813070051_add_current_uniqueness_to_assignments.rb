class AddCurrentUniquenessToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_index :assignments,
      [ :membership_id, :kind ],
      unique: true,
      where: "team_id IS NULL AND ends_on IS NULL",
      name: "idx_unique_current_club_assignments"

    add_index :assignments,
      [ :membership_id, :team_id, :kind ],
      unique: true,
      where: "team_id IS NOT NULL AND ends_on IS NULL",
      name: "idx_unique_current_team_assignments"
  end
end
