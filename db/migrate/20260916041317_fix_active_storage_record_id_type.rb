class FixActiveStorageRecordIdType < ActiveRecord::Migration[8.0]
	def up
		# Drop the unique index first; change_column can't rebuild it cleanly
		remove_index :active_storage_attachments,
								name: "index_active_storage_attachments_uniqueness"

		change_column :active_storage_attachments, :record_id, :string

		add_index :active_storage_attachments,
							[ :record_type, :record_id, :name, :blob_id ],
							unique: true,
							name: "index_active_storage_attachments_uniqueness"

		# Rows written while the column was bigint are garbage (record_id = 0).
		# They point at no real record, so purge them.
		ActiveStorage::Attachment.where(record_id: "0").find_each(&:purge_later)
	end

	def down
		remove_index :active_storage_attachments,
								name: "index_active_storage_attachments_uniqueness"
		change_column :active_storage_attachments, :record_id, :bigint
		add_index :active_storage_attachments,
							[ :record_type, :record_id, :name, :blob_id ],
							unique: true,
							name: "index_active_storage_attachments_uniqueness"
	end
end
