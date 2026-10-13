class AddAnonymizedAtAndRefineRegistrations < ActiveRecord::Migration[8.0]
	def change
		add_column :admission_people, :anonymized_at, :datetime
		add_column :people,           :anonymized_at, :datetime
		add_column :registrations,    :anonymized_at, :datetime
		add_column :users,            :anonymized_at, :datetime

		rename_column :registrations, :submitted_at, :sent_for_review_at

		# Drop refs the approval flow no longer needs
		remove_reference :registrations, :membership, type: :uuid, foreign_key: true
		remove_reference :registrations, :assignment, type: :uuid, foreign_key: true
	end
end
