class CreateCoaches < ActiveRecord::Migration[6.1]
  def change
    create_table :coaches do |t|
      t.boolean :active
      t.references :person, null: false, foreign_key: true, default: 0

      t.timestamps
    end
#    Coach.create(id: 0, active: false, person_id: 0)
  end
end
