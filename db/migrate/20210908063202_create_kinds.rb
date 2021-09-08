class CreateKinds < ActiveRecord::Migration[6.1]
  def change
    create_table :kinds do |t|
      t.string :name

      t.timestamps
    end
    Kind.create(id: 0, name: "")
  end
end