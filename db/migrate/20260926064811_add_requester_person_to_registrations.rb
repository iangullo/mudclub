class AddRequesterPersonToRegistrations < ActiveRecord::Migration[8.0]
	def up
		add_column :registrations, :requester_person_id, :bigint
		add_index  :registrations, :requester_person_id
		add_foreign_key :registrations, :people,
										column: :requester_person_id
	end

	def down
		remove_foreign_key :registrations, column: :requester_person_id
		remove_index  :registrations, :requester_person_id
		remove_column :registrations, :requester_person_id
	end
end
