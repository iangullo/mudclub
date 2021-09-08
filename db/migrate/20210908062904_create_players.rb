class CreatePlayers < ActiveRecord::Migration[6.1]
  def change
    create_table :players do |t|
      t.integer :number
      t.boolean :active
      t.references :person, null: false, foreign_key: true, default: 0

      t.timestamps
    end
    Player.create(id: 0, number: 0, active: false, person_id: 0)
  end
end
