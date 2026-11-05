class MigrateStatsToAthletes < ActiveRecord::Migration[8.0]
	# Index names that may linger from aborted attempts.
	LEGACY_INDEXES = %w[
		idx_stats_unique_owner
		idx_stats_unique_team_rival
		idx_stats_unique_athlete
		index_stats_on_event_id_and_player_id_and_concept
		index_stats_on_athlete_id
	].freeze

	def up
		LEGACY_INDEXES.each { |idx| execute "DROP INDEX IF EXISTS #{idx}" }

		# Defensive cleanup: if a prior attempt left athlete_id as bigint, drop it.
		if column_exists?(:stats, :athlete_id) &&
			column_for(:stats, :athlete_id).type != :uuid
			if execute("SELECT 1 FROM stats WHERE athlete_id IS NOT NULL LIMIT 1").any?
				raise "stats.athlete_id contains data but is the wrong type — inspect manually"
			end
			remove_column :stats, :athlete_id
		end

		# ── 1. Schema changes ────────────────────────────────────────────────
		add_column :stats, :athlete_id, :uuid unless column_exists?(:stats, :athlete_id)
		add_column :stats, :kind, :integer, null: false, default: 2 unless column_exists?(:stats, :kind)

		remove_foreign_key :stats, :players, if_exists: true
		change_column_null :stats, :player_id, true

		unless foreign_key_exists?(:stats, :assignments)
			add_foreign_key :stats, :assignments, column: :athlete_id
		end

		# ── 2. Backfill kind from player_id sentinels ────────────────────────
		execute "UPDATE stats SET kind = 0 WHERE player_id = 0"
		execute "UPDATE stats SET kind = 1 WHERE player_id = -1"

		# ── 3. Backfill athlete_id from legacy player_id ─────────────────────
		# Single SQL UPDATE — replaces the rake task.
		# `kind` on Assignment is a Kinded enum; retrieve the integer from the
		# catalog (immutable, safe to load in a migration).
		# Two distinct enums:
		# - assignment_athlete filters assignments.kind (Catalog::AssignmentKinds)
		# - stat_athlete       filters stats.kind       (Catalog::StatKinds)
		assignment_athlete = Catalog::AssignmentKinds.enum.fetch(:athlete)
		stat_athlete       = Catalog::StatKinds.enum.fetch(:athlete)

		result = execute <<~SQL
      UPDATE stats s
      SET athlete_id = a.id
      FROM events e
      JOIN assignments a ON a.team_id = e.team_id AND a.kind = #{assignment_athlete}
      JOIN memberships m ON m.id = a.membership_id
      JOIN people      p ON p.id = m.person_id
      JOIN players    pl ON pl.person_id = p.id
      WHERE s.event_id  = e.id
        AND s.player_id = pl.id
        AND s.kind      = #{stat_athlete}
        AND s.athlete_id IS NULL
		SQL

		migrated = result.respond_to?(:cmd_tuples) ? result.cmd_tuples : result.to_a.size
		say "Migrated #{migrated} athlete stat(s) to athlete_id.", true

		# Optional: report orphans so the operator can inspect before indexes land.
		orphans = execute(<<~SQL).first["count"].to_i
      SELECT count(*) AS count FROM stats
      WHERE kind = 2 AND athlete_id IS NULL AND player_id > 0
		SQL
		say "Note: #{orphans} athlete stat(s) could not be linked to an Assignment", true if orphans > 0

		# ── 4. Uniqueness indexes ────────────────────────────────────────────
		add_index :stats,
			%i[event_id concept period athlete_id],
			unique: true,
			where:  "athlete_id IS NOT NULL",
			name:   "idx_stats_unique_athlete"

		add_index :stats,
			%i[event_id concept period kind],
			unique: true,
			where:  "athlete_id IS NULL",
			name:   "idx_stats_unique_team_rival"
	end

	def down
		execute "DROP INDEX IF EXISTS idx_stats_unique_athlete"
		execute "DROP INDEX IF EXISTS idx_stats_unique_team_rival"

		# Reverse the athlete_id → player_id backfill for athlete rows so we can
		# restore the NOT NULL constraint on player_id.
		stat_athlete = Catalog::StatKinds.enum.fetch(:athlete)
		execute <<~SQL
      UPDATE stats s
      SET player_id = pl.id
      FROM assignments a
      JOIN memberships m ON m.id = a.membership_id
      JOIN people      p ON p.id = m.person_id
      JOIN players    pl ON pl.person_id = p.id
      WHERE s.athlete_id = a.id
        AND s.kind       = #{stat_athlete}
        AND s.player_id IS NULL
		SQL

		# If any row still lacks player_id (orphan athlete row created after the
		# migration and with no legacy Player row), do NOT enforce NOT NULL —
		# rollback would otherwise be destructive. Warn instead.
		remaining = execute("SELECT count(*) AS c FROM stats WHERE player_id IS NULL").first["c"].to_i
		if remaining.zero?
			change_column_null :stats, :player_id, false
		else
			say "WARNING: #{remaining} stat(s) have no player_id — leaving player_id nullable on rollback", true
		end

		remove_foreign_key :stats, :assignments, if_exists: true
		add_foreign_key :stats, :players unless foreign_key_exists?(:stats, :players)

		remove_column :stats, :athlete_id if column_exists?(:stats, :athlete_id)
		remove_column :stats, :kind       if column_exists?(:stats, :kind)

		LEGACY_INDEXES.each { |idx| execute "DROP INDEX IF EXISTS #{idx}" }
	end

	private

	def column_for(table, name)
		connection.columns(table).find { |c| c.name == name.to_s }
	end
end
