class AddAddressToPeople < ActiveRecord::Migration[7.0]
  def change
    add_column :people, :address, :string
  end
end
