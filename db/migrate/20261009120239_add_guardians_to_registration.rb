class AddGuardiansToRegistration < ActiveRecord::Migration[8.0]
	def change
		add_reference :registrations, :guardian1, null: true,
									foreign_key: { to_table: :admission_people }
		add_reference :registrations, :guardian2, null: true,
									foreign_key: { to_table: :admission_people }
	end
end
