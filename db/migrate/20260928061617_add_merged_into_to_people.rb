class AddMergedIntoToPeople < ActiveRecord::Migration[8.0]
	def change
		add_reference :people,
									:merged_into,
									foreign_key: { to_table: :people },
									index: true,
									default: :null,
									null: true
	end
end
