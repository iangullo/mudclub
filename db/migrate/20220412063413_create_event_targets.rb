class CreateEventTargets < ActiveRecord::Migration[6.1]
  def change
    create_table :event_targets do |t|
      t.integer :priority
      t.belongs_to :event, null: false, foreign_key: true
      t.belongs_to :target, null: false, foreign_key: true

      t.timestamps
    end
  end
end
