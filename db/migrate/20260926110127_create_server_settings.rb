class CreateServerSettings < ActiveRecord::Migration[8.0]
	def change
		create_table :server_settings, id: :bigint do |t|
			t.jsonb :settings, null: false, default: {}
			t.timestamps
		end
	end
end
