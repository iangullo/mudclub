class AddClubToUserActions < ActiveRecord::Migration[8.0] # match your schema version
	class MigrationUserAction < ActiveRecord::Base
		self.table_name = "user_actions"
	end

	class MigrationClub < ActiveRecord::Base
		self.table_name = "clubs"
	end

	def up
		add_reference :user_actions, :club, null: true, foreign_key: { on_delete: :nullify }
		add_index :user_actions, [ :club_id, :updated_at ]

		MigrationUserAction.reset_column_information
		valid_club_ids = MigrationClub.pluck(:id).to_set

		MigrationUserAction.where("url LIKE ?", "/clubs/%").find_each do |action|
			next unless (match = action.url.match(%r{\A/clubs/(\d+)}))

			club_id = match[1].to_i
			action.update_columns(club_id:) if valid_club_ids.include?(club_id)
		end
	end

	def down
		remove_index :user_actions, [ :club_id, :updated_at ]
		remove_reference :user_actions, :club, foreign_key: true
	end
end
