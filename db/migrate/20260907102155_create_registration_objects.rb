class CreateRegistrationObjects < ActiveRecord::Migration[8.0]
	def up
		create_table :registrations, id: :uuid do |t|
			t.references :club, null: false, foreign_key: true

			t.integer :kind, null: false
			t.integer :requester_kind, null: false, default: 1	# draft
			t.references :requested_team, foreign_key: { to_table: :teams }
			t.boolean :request_user, default: false
			t.jsonb :settings, default: {}
			t.text :remarks
			t.datetime :submitted_at
			t.datetime :reviewed_at

			# applicant
			t.string :candidate_name, null: false
			t.string :candidate_surname, null: false
			t.date   :candidate_birthday
			t.boolean :candidate_female
			t.string :candidate_email
			t.string :candidate_phone

			# requester
			t.string :requester_name
			t.string :requester_email
			t.string :requester_phone

			# reviewer
			t.references :reviewer, foreign_key: { to_table: :users }

			# application outcomes
			t.integer :status, null: false, default: 1
			t.references :membership, null: true, foreign_key: true, type: :uuid, default: nil
			t.references :assignment, null: true, foreign_key: true, type: :uuid, default: nil
			t.references :accepted_document,
						type: :uuid,
						null: true,
						foreign_key: { to_table: :documents }

			t.datetime :accepted_terms_at
			t.string   :accepted_terms_ip

			t.timestamps
		end

		# add references for registrations in documents
		add_reference :documents, :registration, type: :uuid, foreign_key: true
		add_index :documents, [ :registration_id, :kind ]

		add_index :registrations, :kind
		add_index :registrations, :request_user
		add_index :registrations, [ :club_id, :status ]
		add_index :registrations, [ :requested_team_id, :status ]

		create_table :registration_messages do |t|
			t.references :registration, null: false, type: :uuid, foreign_key: true

			t.integer :author_kind, null: false
			t.text :body, null: false
			t.boolean :visible_to_requester, default: true
			t.boolean :internal, default: false

			t.timestamps
		end

		add_index :registration_messages, [ :registration_id, :created_at ]
	end

	def down
		remove_reference :documents, :registration
		drop_table :registration_messages
		drop_table :registrations
	end
end
