class AddUrlToUserAction < ActiveRecord::Migration[7.0]
  def change
    add_column :user_actions, :url, :string
  end
end
