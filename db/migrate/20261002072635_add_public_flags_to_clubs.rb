class AddPublicFlagsToClubs < ActiveRecord::Migration[8.0]
	def up
		add_column :clubs, :public, :boolean, null: false, default: false
		add_index  :clubs, :public, where: "public = TRUE"

		# Optional: track when/what admin last approved it
		add_column :clubs, :public_approved_at, :datetime
		add_column :clubs, :public_approved_by_id, :bigint
		add_foreign_key :clubs, :users, column: :public_approved_by_id

		club  = Club.first
		admin = User.admin.first

		if club && admin
			now   = DateTime.current
			club.update! public: true, public_approved_by_id: admin.id, public_approved_at: now
		end
	end

	def down
		remove_foreign_key :clubs, column: :public_approved_by_id
		remove_column :clubs, :public_approved_by_id
		remove_column :clubs, :public_approved_at
		remove_index  :clubs, :public
		remove_column :clubs, :public
	end
end
