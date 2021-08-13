class AddDniToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :dni, :string
  end
end
