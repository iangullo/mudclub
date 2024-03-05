class CreateClubs < ActiveRecord::Migration[7.0]
	def change
		create_table :clubs do |t|
			t.string :name
			t.string :nick
			t.string :email
			t.string :phone
			t.string :address
			t.jsonb :settings

			t.timestamps
		end
		
		# Seed default club records
		clubperson = Person.find_by_id(0)
		mudclub = Club.create!(
			id: 0,
			name: (clubperson&.name || "MudClub Basketball"),
			nick: (clubperson&.nick || "MudClub"),
			email: clubperson&.email || "mudclub@mudclub.org",
			settings: {
				locale: 'en',
				country: 'US',
				social_media: {},
				website: "https://github.com/iangullo/mudclub/wiki"
			}
		)
		
		# Copy avatar attachment from Person to Club 0
		mudclub.avatar.attach(clubperson.avatar.blob) if clubperson&.avatar&.attached?

		# Add references for related models and change club_id columns to allow NULL values
		%w(teams players coaches users).each do |table_name|
			add_reference table_name.to_sym, :club, foreign_key: true, null: false, default: 0
			change_column table_name.to_sym, :club_id, :bigint, null: true
		end

		# deactivate inactive/placeholder records
    Person.where(dni: "").update_all(dni: nil)
    Person.where(email: "").update_all(email: nil)
    Person.where(phone: "").update_all(phone: nil)
    Coach.where(active: false).update_all(club_id: nil)
    Player.where(active: false).update_all(club_id: nil)
	end
end
