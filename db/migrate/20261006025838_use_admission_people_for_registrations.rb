class UseAdmissionPeopleForRegistrations < ActiveRecord::Migration[8.0]
	def change
		create_table :admission_people, id: :uuid do |t|
			t.string  :name
			t.string  :surname
			t.date    :birthday
			t.boolean :female

			t.string  :dni
			t.string  :email
			t.string  :phone
			t.string  :nick
			t.string  :address

			t.timestamps
		end

		# add anonymous access_tokens
		add_column :registrations, :access_token, :string
		add_column :registrations, :access_token_expires_at, :datetime
		add_index  :registrations, :access_token, unique: true

		# new references for Person / AdmissionPerson objects
		add_reference :registrations, :candidate, type: :uuid,
									foreign_key: { to_table: :admission_people },
									null: false
		add_reference :registrations, :guardian1, type: :uuid, null: true,
									foreign_key: { to_table: :admission_people }
		add_reference :registrations, :guardian2, type: :uuid, null: true,
									foreign_key: { to_table: :admission_people }
		add_reference :registrations, :requester, type: :uuid,
									foreign_key: { to_table: :admission_people },
									null: false
		add_reference :registrations, :submitted_by, type: :bigint,
									foreign_key: { to_table: :people }, null: true

		# Remove older implementation data columns
		remove_column :registrations, :candidate_name, :string
		remove_column :registrations, :candidate_surname, :string
		remove_column :registrations, :candidate_birthday, :date
		remove_column :registrations, :candidate_female, :boolean
		remove_column :registrations, :candidate_email, :string
		remove_column :registrations, :candidate_phone, :string
		remove_column :registrations, :requester_name, :string
		remove_column :registrations, :requester_email, :string
		remove_column :registrations, :requester_phone, :string
		remove_column :registrations, :requester_person_id, :bigint
	end
end
