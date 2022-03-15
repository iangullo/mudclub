class AddIndexToKinds < ActiveRecord::Migration[6.1]
  def change
    add_index :kinds, :name
  end
end
