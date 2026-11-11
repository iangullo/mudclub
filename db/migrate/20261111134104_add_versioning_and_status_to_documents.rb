class AddVersioningAndStatusToDocuments < ActiveRecord::Migration[7.1]
	# Snapshot ids — do NOT reference Catalog::DocumentStatuses.id(...) here.
	# Migrations must survive future catalog refactors.
	DRAFT = 10; PENDING = 20; VERIFIED = 30; ACTIVE = 40
	# (REJECTED = 50, SUPERSEDED = 60, ARCHIVED = 70 are not needed for backfill)

	def up
		add_column :documents, :status,         :integer, default: DRAFT, null: false
		add_column :documents, :version,        :integer, default: 1,     null: false
		add_column :documents, :activated_at,   :datetime
		add_column :documents, :superseded_at,  :datetime
		add_column :documents, :superseded_by_id, :uuid

		add_index :documents, :status
		add_index :documents, :superseded_by_id
		add_index :documents, %i[club_id kind version]
		add_index :documents, %i[registration_id kind version]
		add_index :documents, %i[person_id kind version]
		add_foreign_key :documents, :documents, column: :superseded_by_id

		say_with_time "Backfilling document status" do
			Document.reset_column_information
			Document.find_each do |doc|
				legacy_active   = doc.read_attribute(:active)
				legacy_verified = doc.read_attribute(:verified)
				new_status =
					if    legacy_active   then ACTIVE
					elsif legacy_verified then VERIFIED
					else                       DRAFT
					end
				doc.update_columns(
					status:       new_status,
					version:      1,
					activated_at: legacy_active ? (doc.read_attribute(:verified_at) || doc.created_at) : nil
				)
			end
		end

		remove_column :documents, :active
		remove_column :documents, :verified
	end

	def down
		add_column :documents, :active, :boolean, default: true
		add_column :documents, :verified, :boolean, default: false
		Document.reset_column_information
		Document.find_each do |doc|
			doc.update_columns(active: doc.status == "active",
												verified: %w[verified active superseded].include?(doc.status))
		end
		remove_foreign_key :documents, column: :superseded_by_id
		remove_column :documents, :superseded_by_id
		remove_column :documents, :superseded_at
		remove_column :documents, :activated_at
		remove_column :documents, :version
		remove_column :documents, :status
	end
end
