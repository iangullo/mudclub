class AddHomeToEvent < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :home, :boolean, default: true, after: :name
  end
end
