class CreateStats < ActiveRecord::Migration[6.1]
  def change
    create_table :stats do |t|
      t.belongs_to :event, null: false, foreign_key: true
      t.belongs_to :player, null: false, foreign_key: true
      t.integer :concept
      t.integer :value

      t.timestamps
    end
    Player.create(id: -1, number: 0, active: false, person_id: 0) # fake player to track rival stats
  end
end
