class UseAdmissionPeopleForRegistrations < ActiveRecord::Migration[8.0]
	def change
		create_table :admission_people do |t|
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

		add_reference :registrations,
									:candidate,
									foreign_key: { to_table: :admission_people },
									null: false

		add_reference :registrations,
									:requester,
									foreign_key: { to_table: :admission_people },
									null: false

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
