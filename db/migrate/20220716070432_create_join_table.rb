class CreateJoinTable < ActiveRecord::Migration[7.0]
  def change
    create_join_table :events, :players do |t|
      t.index :event_id
      t.index :player_id
      #t.index [:player_id, :event_id]
    end
  end
end
