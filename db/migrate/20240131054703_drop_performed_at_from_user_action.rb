class DropPerformedAtFromUserAction < ActiveRecord::Migration[7.0]
  def change
    remove_column :user_actions, :performed_at
  end
end
