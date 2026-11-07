class CreateDocuments < ActiveRecord::Migration[8.0]
	def up
		create_table :documents, id: :uuid do |t|
			t.references :club, 				foreign_key: true
			t.references :person,				foreign_key: true

			t.integer :kind, null: false

			t.string	:title
			t.text		:summary
			t.text		:remarks

			t.boolean :verified, default: false
			t.datetime :verified_at

			t.boolean :active, default: false

			t.timestamps
		end

		add_index :documents, [ :club_id, :kind ]
		add_index :documents, [ :person_id, :kind ]
	end

	def down
		drop_table :documents
	end
end
