class CreatePersonRelationships < ActiveRecord::Migration[8.0]
	class RelationshipRecord < ApplicationRecord
		self.table_name = "person_relationships"
	end

	def up
		create_table :person_relationships do |t|
			t.references :person,
									null: false,
									foreign_key: true

			t.references :related_person,
									null: false,
									foreign_key: { to_table: :people }

			t.integer :kind, null: false

			t.date :starts_on
			t.date :ends_on

			t.timestamps
		end

		add_index :person_relationships,
							[ :person_id, :related_person_id, :kind ],
							unique: true,
							where: "ends_on IS NULL",
							name: "idx_unique_active_person_relationships"
		infer_parents_from_legacy
	end

	def down
		drop_table :person_relationships
	end

	private
	def infer_parents_from_legacy
		@duplicates  = 0
		@created     = 0

		forward_kind = Catalog::RelationshipKinds[:parent].id
		reverse_kind = Catalog::RelationshipKinds[:child].id

		Player.find_each do |player|
			next unless player.person_id

			player.parents.each do |parent|
				next unless parent.person_id

				create_relationship(
					person_id: player.person_id,
					related_person_id: parent.person_id,
					kind: forward_kind
				)

				create_relationship(
					person_id: parent.person_id,
					related_person_id: player.person_id,
					kind: reverse_kind
				)
			end
		end

		say "#{@created} relationships created"
		say "#{@duplicates} duplicate relationships skipped"
	end

	def create_relationship(person_id:, related_person_id:, kind:)
		attrs = { person_id:, related_person_id:, kind: }

		if RelationshipRecord.exists?(attrs.merge(ends_on: nil))
			@duplicates += 1
		else
			RelationshipRecord.create!(attrs)
			@created += 1
		end
	end
end
