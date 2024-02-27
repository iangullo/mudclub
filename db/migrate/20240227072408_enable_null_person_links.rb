class EnableNullPersonLinks < ActiveRecord::Migration[7.0]
  def change
    # Change the club_id columns in players, coaches, and users tables to allow NULL values
    change_column :people, :coach_id, :bigint, null: true, default: nil
    change_column :people, :parent_id, :bigint, null: true, default: nil
    change_column :people, :player_id, :bigint, null: true, default: nil
    change_column :people, :user_id, :bigint, null: true, default: nil

    Person.real.where(coach_id: 0).update_all(coach_id: nil)
    Person.real.where(parent_id: 0).update_all(parent_id: nil)
    Person.real.where(player_id: 0).update_all(player_id: nil)
    Person.real.where(user_id: 0).update_all(user_id: nil)
  end
end
