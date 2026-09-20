class AddAuthorToDrills < ActiveRecord::Migration[8.0]
	def up
		add_reference :drills, :author, null: true, foreign_key: { to_table: :people }

		# Backfill from legacy coach
		execute <<~SQL
      UPDATE drills d
         SET author_id = c.person_id
        FROM coaches c
       WHERE d.coach_id = c.id
         AND d.coach_id > 0
		SQL
	end

	def down
		remove_reference :drills, :author
	end
end
