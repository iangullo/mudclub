class AddFieldsToPerson < ActiveRecord::Migration[6.1]
  def change
    add_reference :people, :player, null: false, foreign_key: true, default: 0
    add_reference :people, :coach, null: false, foreign_key: true, default: 0
  end
end
