class MoveLocaleToSettings < ActiveRecord::Migration[7.0]
	def up
		add_column :users, :settings, :jsonb, default: {}

		User.reset_column_information
		User.find_each do |user|
			user.update_column(:settings, { locale: user.locale }) if user.locale.present?
		end

		remove_column :users, :locale
	end
	
	def down
		add_column :users, :locale, :integer

		User.reset_column_information
		User.find_each do |user|
			user.update_column(:locale, User.locales[user.settings['locale']]) if user.settings['locale'].present?
		end

		remove_column :users, :settings
	end
end
