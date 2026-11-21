# db/migrate/20261116XXXXXX_rename_kinds_to_drill_categories.rb
class RenameKindsToDrillCategories < ActiveRecord::Migration[8.0]
	def up
		rename_table  :kinds, :drill_categories
		rename_column :drills, :kind_id, :category_id

		# Additive columns for Part 2.
		add_reference :drill_categories, :sport, foreign_key: true
		add_column    :drill_categories, :catalog_key, :integer
		add_column    :drill_categories, :club_id,     :bigint
		add_index     :drill_categories, :catalog_key
		add_index     :drill_categories, :club_id

		# Backfill sport_id from dominant drill sport.
		execute <<~SQL
      UPDATE drill_categories dc
      SET    sport_id = (
        SELECT d.sport_id FROM drills d
        WHERE  d.category_id = dc.id
        GROUP  BY d.sport_id
        ORDER  BY COUNT(*) DESC, d.sport_id ASC
        LIMIT  1
      )
		SQL

		# Deduplicate within (LOWER(TRIM(name)), sport_id), keep min id.
		# Sentinel id = 0 excluded on both sides.
		execute <<~SQL
      WITH keepers AS (
        SELECT MIN(id) AS keep_id, LOWER(TRIM(name)) AS lname, sport_id
        FROM   drill_categories WHERE id > 0
        GROUP  BY LOWER(TRIM(name)), sport_id
      )
      UPDATE drills d
      SET    category_id = keepers.keep_id
      FROM   drill_categories dc, keepers
      WHERE  d.category_id = dc.id
        AND  dc.id > 0
        AND  dc.id <> keepers.keep_id
        AND  LOWER(TRIM(dc.name)) = keepers.lname
        AND  dc.sport_id IS NOT DISTINCT FROM keepers.sport_id;
		SQL

		execute <<~SQL
      DELETE FROM drill_categories dc
      USING (
        SELECT MIN(id) AS keep_id, LOWER(TRIM(name)) AS lname, sport_id
        FROM   drill_categories WHERE id > 0
        GROUP  BY LOWER(TRIM(name)), sport_id
      ) keepers
      WHERE  dc.id <> keepers.keep_id
        AND  dc.id > 0
        AND  LOWER(TRIM(dc.name)) = keepers.lname
        AND  dc.sport_id IS NOT DISTINCT FROM keepers.sport_id;
		SQL

		say "drill_categories: #{select_value('SELECT COUNT(*) FROM drill_categories WHERE sport_id IS NULL')} row(s) with sport_id = NULL"
	end

	def down
		remove_index  :drill_categories, :club_id
		remove_index  :drill_categories, :catalog_key
		remove_column :drill_categories, :club_id
		remove_column :drill_categories, :catalog_key
		remove_reference :drill_categories, :sport

		rename_index :drill_categories, "index_drill_categories_on_name", "index_kinds_on_name"
		rename_column :drills, :category_id, :kind_id
		rename_table  :drill_categories, :kinds
	end
end
