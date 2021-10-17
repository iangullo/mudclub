class CreateDivisions < ActiveRecord::Migration[6.1]
  def change
    create_table :divisions do |t|
      t.string :name

      t.timestamps
    end
    Division.create(id: 0, name: "None")
  end
end
