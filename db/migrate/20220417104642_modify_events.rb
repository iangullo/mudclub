class ModifyEvents < ActiveRecord::Migration[6.1]
  def change
    rename_column :events, :start, :start_time
    remove_column :events, :duration
    add_column :events, :end_time, :datetime, after: :start_time
    add_column :events, :name, :string, after: :end_time
  end
end
