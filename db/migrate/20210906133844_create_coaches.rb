class CreateCoaches < ActiveRecord::Migration[6.1]
  def change
    create_table :coaches do |t|
      t.boolean :active
      t.references :person, null: false, foreign_key: true

      t.timestamps
    end
  end
end
