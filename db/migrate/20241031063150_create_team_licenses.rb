class CreateTeamLicenses < ActiveRecord::Migration[7.2]
	def change
		create_table :team_licenses do |t|
			t.references :team, null: false, foreign_key: true
			t.references :person, null: false, foreign_key: true
			t.integer :kind	# 0=>:player, 1=>:coach, 2=>:delegate

			t.timestamps
		end

		Team.real.each do |team|  # transfer from old Join tables
			team.players.each do |player|
				TeamLicense.create(team:, person: player.person, kind: 0) if player.all_pics?
			end
			team.coaches.each do |coach|
				TeamLicense.create(team:, person:coach.person, kind: 1) if coach.all_pics?
			end
		end
	end
end
