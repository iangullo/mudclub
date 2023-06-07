class CreateParents < ActiveRecord::Migration[7.0]
  def change
    create_table :parents do |t|
      t.references :person, null: false, foreign_key: true

      t.timestamps
    end
    Parent.create(id: 0, person_id: 0)
    add_reference :people, :parent, null: false, foreign_key: true, default: 0
  end
end
