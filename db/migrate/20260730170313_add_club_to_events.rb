class AddClubToEvents < ActiveRecord::Migration[8.0]
  def up
    add_reference :events, :club, null: true

    # Existing team events inherit their club from the team.
    execute <<~SQL
      UPDATE events
      SET club_id = teams.club_id
      FROM teams
      WHERE events.team_id = teams.id
    SQL

    # Club-level events use the first/single club (id: 0).
    execute <<~SQL
      UPDATE events
      SET club_id = 0
      WHERE club_id IS NULL
    SQL

    change_column_null :events, :club_id, false
    change_column_null :events, :team_id, true
  end

  def down
    change_column_null :events, :team_id, false
    remove_reference :events, :club
  end
end
