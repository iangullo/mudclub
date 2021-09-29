class DropDniFromPeople < ActiveRecord::Migration[6.1]
  def change
    remove_column :people, :dni, :string
  end
end
