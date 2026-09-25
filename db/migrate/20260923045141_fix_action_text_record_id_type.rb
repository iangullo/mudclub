class FixActionTextRecordIdType < ActiveRecord::Migration[8.0]
	def up
		remove_index :action_text_rich_texts,
								name: "index_action_text_rich_texts_uniqueness"

		change_column :action_text_rich_texts, :record_id, :string

		# Rows written while the column was bigint were coerced to 0.
		# They point at no real record — purge them before recreating the index.
		execute "DELETE FROM action_text_rich_texts WHERE record_id = '0'"

		add_index :action_text_rich_texts,
							[ :record_type, :record_id, :name ],
							unique: true,
							name: "index_action_text_rich_texts_uniqueness"
	end

	def down
		remove_index :action_text_rich_texts,
								name: "index_action_text_rich_texts_uniqueness"

		change_column :action_text_rich_texts, :record_id, :bigint

		add_index :action_text_rich_texts,
							[ :record_type, :record_id, :name ],
							unique: true,
							name: "index_action_text_rich_texts_uniqueness"
	end
end
