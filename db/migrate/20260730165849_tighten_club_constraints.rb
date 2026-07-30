class TightenClubConstraints < ActiveRecord::Migration[8.0]
	def change
		#
		# Mandatory attributes
		#
		change_column_null :clubs, :name, false
		change_column_null :clubs, :nick, false

		#
		# Remove existing non-unique indexes (if present)
		#
		remove_index :clubs, :name  if index_exists?(:clubs, :name)
		remove_index :clubs, :nick  if index_exists?(:clubs, :nick)
		remove_index :clubs, :email if index_exists?(:clubs, :email)
		remove_index :clubs, :phone if index_exists?(:clubs, :phone)

		#
		# Enforce uniqueness
		#
		add_index :clubs, :name, unique: true
		add_index :clubs, :nick, unique: true
		add_index :clubs, :email, unique: true
		add_index :clubs, :phone, unique: true
	end
end
