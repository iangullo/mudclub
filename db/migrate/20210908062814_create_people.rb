class CreatePeople < ActiveRecord::Migration[6.1]
  def change
    create_table :people do |t|
      t.string :dni
      t.string :nick
      t.string :name
      t.string :surname
      t.date :birthday
      t.boolean :female

      t.timestamps
    end
    Person.create(id: 0, nick: 'New', name: 'Nueva', surname: 'Persona', birthday: Date.today, female: true)
  end
end
