class CreateMoments < ActiveRecord::Migration[8.0]
	def change
		add_column :events, :video_url, :string

		# timestamped coaching notes on a match video
		create_table :moments do |t|
			t.references :event, null: false, foreign_key: true
			t.references :player, foreign_key: true	# NULL: whole team
			t.integer :second, null: false, default: 0
			t.integer :kind, null: false, default: 0
			t.string :note, null: false
			t.timestamps
		end
		add_check_constraint :moments, "second >= 0", name: "moment_second_check"
	end
end
