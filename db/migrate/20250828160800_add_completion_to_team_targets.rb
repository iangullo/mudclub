class AddCompletionToTeamTargets < ActiveRecord::Migration[8.0]
	def change
		add_column :team_targets, :completion, :integer, default: 0, null: false
		add_check_constraint :team_targets, 'completion >= 0 AND completion <= 100', name: 'completion_range_check'
	end
end
