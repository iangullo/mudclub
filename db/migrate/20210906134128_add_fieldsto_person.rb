class AddFieldstoPerson < ActiveRecord::Migration[6.1]
  def change
    add_reference :people, :player, null: false, foreign_key: true
    add_reference :people, :coach, null: false, foreign_key: true
  end
end
