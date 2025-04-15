class AddSportAndCourtToDrills < ActiveRecord::Migration[8.0]
	def change
		add_reference :drills, :sport, foreign_key: true, default: 1
		add_column :drills, :court_mode, :string, default: "full"
	end
end
