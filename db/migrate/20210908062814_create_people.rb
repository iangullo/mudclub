class CreatePeople < ActiveRecord::Migration[6.1]
  def change
    create_table :people do |t|
      t.string :dni
      t.string :nick
      t.string :name
      t.string :surname
      t.date :birthday
      t.boolean :female
      t.string :email
      t.string :phone

      t.timestamps
    end
    ActiveRecord::Base.connection.execute("INSERT INTO people (id, dni, name, surname, birthday, female, email, phone, created_at, updated_at) values (0,'00000000A','MudClub','Persona','2021-09-01',TRUE,'fake@mudclub.org','+34 666666666','2021-09-13 08:12','2021-09-13 08:12')")
    ActiveRecord::Base.connection.execute("INSERT INTO people (id, dni, name, surname, birthday, female, email, phone, created_at, updated_at) values (1,'00000000B','Admin','MudClub','2021-09-01',TRUE,'admin@mudclub.org','+34 666666666','2021-09-13 08:12','2021-09-13 08:12')")
  end
end
