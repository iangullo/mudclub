class AddLockedToTeams < ActiveRecord::Migration[8.0]
	def change
		add_column :teams, :locked, :boolean, default: true, null: false
		add_index  :teams, :locked
	end
end
