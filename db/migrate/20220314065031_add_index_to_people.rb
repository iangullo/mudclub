class AddIndexToPeople < ActiveRecord::Migration[6.1]
  def change
    add_index :people, :name
    add_index :people, :surname
  end
end
