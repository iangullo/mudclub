class AddUserToPerson < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.connection.execute("INSERT INTO users (id, email, role, person_id, created_at, updated_at) values (0,'fake@bclub.org',0,0,'2021-09-13 08:12','2021-09-13 08:12')")
    add_reference :people, :user, null: false, foreign_key: true, default: 0

    # additional data to link well in bclub database
    # fake user_id (0)
    User.create(email: 'admin@bclub.org', role: :admin, password: 'bclub-admin', password_confirmation: 'bclub-admin', person_id: 1)
    User.last.person=Person.find_by(email: 'admin@bclub.org')
  end
end
