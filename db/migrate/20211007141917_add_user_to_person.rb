class AddUserToPerson < ActiveRecord::Migration[6.1]
  def change
    add_reference :people, :user, null: false, foreign_key: true, default: 0

    # additional data to link well in bclub database
    # initial admin user
    User.create(email: 'admin@bclub.org', role: :admin, password: 'bclub-admin', password_confirmation: 'bclub-admin', person_id: 1)
    User.last.person=Person.find_by(email: 'admin@bclub.org')
  end
end
