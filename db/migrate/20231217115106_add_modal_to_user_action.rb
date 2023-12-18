class AddModalToUserAction < ActiveRecord::Migration[7.0]
  def change
    add_column :user_actions, :modal, :boolean
  end
end
