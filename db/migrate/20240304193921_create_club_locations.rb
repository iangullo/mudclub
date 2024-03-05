class CreateClubLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :club_locations do |t|
      t.references :club, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end

    if (club = Club.find(0))
      Location.real.each { |loc| club.locations << loc }
    end
  end
end
