class CreateAttendances < ActiveRecord::Migration[8.0]
  def up
    create_table :attendances do |t|
      t.references :event,      null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true, type: :uuid
      t.integer :status, null: false, default: 0
      t.text :remarks
      t.timestamps
    end

    add_index :attendances,
              [ :event_id, :assignment_id ],
              unique: true

    infer_legacy_attendances
  end

  def down
    drop_table :attendances
  end

  private
    def infer_legacy_attendances
      say_with_time "Migrating legacy attendances" do
        athlete_kind = Catalog::MembershipKinds[:athlete].id

        # Insert (suppress SQL output)
        suppress_messages do
          execute <<~SQL
            INSERT INTO attendances
              (event_id, assignment_id, status, created_at, updated_at)
            SELECT
              ep.event_id,
              a.id,
              1,
              CURRENT_TIMESTAMP,
              CURRENT_TIMESTAMP
            FROM events_players ep
            JOIN players p ON p.id = ep.player_id
            JOIN events e ON e.id = ep.event_id
            JOIN memberships m
              ON m.person_id = p.person_id
             AND m.club_id = e.club_id
             AND m.kind = #{athlete_kind}
             AND m.joined_on <= DATE(e.start_time)
             AND (m.left_on IS NULL OR m.left_on >= DATE(e.start_time))
            JOIN assignments a
              ON a.membership_id = m.id
             AND a.team_id = e.team_id
             AND (a.starts_on IS NULL OR a.starts_on <= DATE(e.start_time))
             AND (a.ends_on   IS NULL OR a.ends_on   >= DATE(e.start_time))
            WHERE e.team_id IS NOT NULL
            ON CONFLICT (event_id, assignment_id) DO NOTHING;
          SQL
        end

        # Diagnostic (suppress SQL output)
        missing = nil
        suppress_messages do
          missing = select_value(<<~SQL).to_i
            SELECT COUNT(*)
            FROM events_players ep
            JOIN players p ON p.id = ep.player_id
            JOIN events e ON e.id = ep.event_id
            LEFT JOIN memberships m
              ON m.person_id = p.person_id
             AND m.club_id = e.club_id
             AND m.kind = #{athlete_kind}
             AND m.joined_on <= DATE(e.start_time)
             AND (m.left_on IS NULL OR m.left_on >= DATE(e.start_time))
            LEFT JOIN assignments a
              ON a.membership_id = m.id
             AND a.team_id = e.team_id
             AND (a.starts_on IS NULL OR a.starts_on <= DATE(e.start_time))
             AND (a.ends_on   IS NULL OR a.ends_on   >= DATE(e.start_time))
            WHERE e.team_id IS NOT NULL
              AND a.id IS NULL;
          SQL
        end

        say "#{missing} attendance record(s) could not be matched to an assignment." if missing.positive?
      end
    end
end
