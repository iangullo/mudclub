class CreateJoinTableUserRoles < ActiveRecord::Migration[7.0]
	def change
		create_join_table :users, :roles do |t|
			t.index [:user_id, :role_id], unique: true
		end

		# Populate the join table with existing roles
		reversible do |dir|
			dir.up do
				User.reset_column_information
				Role.reset_column_information

				admin_role = Role.find_by(name: 'admin')
				manager_role = Role.find_by(name: 'manager')
				coach_role = Role.find_by(name: 'coach')
				player_role = Role.find_by(name: 'player')
				user_role = Role.find_by(name: 'user')

				User.find_each do |user|
					roles = [user_role]

					roles << admin_role if user.admin?
					roles << manager_role if user.is_manager?
					roles << coach_role if user.is_coach?
					roles << player_role if user.is_player?
					roles << user_role unless roles.any?

					roles.each do |role|
						user.roles << role unless user.roles.include?(role)
					end
				end
			end

			dir.down do
				User.find_each do |user|
					user.roles.clear
				end
			end
		end
	end
end
