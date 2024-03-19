class DropActiveFlags < ActiveRecord::Migration[7.0]
  def change  # active is no longer required - determined now by bound club_id
    remove_column :coaches, :active
    remove_column :players, :active
  end
end
