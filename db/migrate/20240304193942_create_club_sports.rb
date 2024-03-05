class CreateClubSports < ActiveRecord::Migration[7.0]
  def change
    create_table :club_sports do |t|
      t.references :club, null: false, foreign_key: true
      t.references :sport, null: false, foreign_key: true

      t.timestamps
    end

    if (club = Club.find(0))
      Sport.all.each { |loc| club.sports << loc }
    end
  end
end
