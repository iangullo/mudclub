class AddLocaleToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :locale, :integer, default: 0
  end
end
