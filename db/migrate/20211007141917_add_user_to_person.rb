class AddUserToPerson < ActiveRecord::Migration[6.1]
  def change
    add_reference :people, :user, null: false, foreign_key: true, default: 0
    User.create(email: 'admin@bclub.org', password: 'bclub-admin', password_confirmation: 'bclub-admin', person_id: 1)
    User.last.person=Person.find_by(email: 'admin@bclub.org')
  end
end
