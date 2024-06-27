class CreateRoles < ActiveRecord::Migration[7.0]
	def change
		create_table :roles do |t|
			t.string :name
			t.jsonb :permissions, default: {}

			t.timestamps
		end

		# Populate with typical roles
		Role.create(
			name: 'admin',
			permissions: {
				categories: [:index, :create, :show, :update, :destroy],
				clubs: [:index, :create, :show, :update, :destroy],
				coaches: [:index, :show, :destroy],
				divisions: [:index, :create, :show, :update, :destroy],
				home: [:log, :clear],
				locations: [:index, :create, :show, :update, :destroy],
				server: [:show, :update],
				seasons: [:index, :create, :show, :update, :destroy],
				sports: [:index, :create, :show, :update, :destroy],
				users: [:index, :create, :show, :update, :destroy],
				players: [:index, :show, :destroy],
			}
		)
		Role.create(
			name: 'manager',
			permissions: {
				clubs: [:index, :show, :update],
				coaches: [:index, :create, :show, :update],
				events: [:index, :create, :show, :update, :destroy],
				home: [:log, :clear],
				locations: [:index, :create, :show, :update, :destroy],
				slots: [:index, :create, :show, :update, :destroy],
				teams: [:index, :create, :show, :update, :destroy],
				players: [:index, :create, :show, :update],
			}
		)
		Role.create(
			name: 'coach',
			permissions: {
				drills: [:index, :create, :show, :update],
				events: [:index, :create, :show, :update, :destroy],
				locations: [:index, :show],
				teams: [:index, :create, :show, :update],
				players: [:index, :create, :show, :update],
			}
		)
		Role.create(
			name: 'secretary',
			permissions: {
				club: [:index, :show],
				events: [:index, :show],
				players: [:index, :create, :show, :update, :destroy],
				teams: [:index, :show]
			}
		)
		Role.create(
			name: 'player',
			permissions: {
				events: [:index, :show],
				stats: [:index, :create, :show, :update],
				teams: [:index, :show]
			}
		)
		Role.create(
			name: 'parent',
			permissions: {
				events: [:index, :show],
				teams: [:index, :show]
			}
		)
		Role.create(
			name: 'user',
			permissions: {
				home: [:index, :about]
			}
		)
	end
end
