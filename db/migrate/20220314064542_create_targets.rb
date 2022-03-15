class CreateTargets < ActiveRecord::Migration[6.1]
  def change
    create_table :targets do |t|
      t.integer :focus
      t.integer :aspect
      t.string :concept

      t.timestamps
    end
    add_index :targets, :concept
  end
end
