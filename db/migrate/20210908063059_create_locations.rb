class CreateLocations < ActiveRecord::Migration[6.1]
  def change
    create_table :locations do |t|
      t.string :name
      t.string :gmaps_url
      t.boolean :practice_court

      t.timestamps
    end
    Location.create(id: 0, name: I18n.t(:l_none), gmaps_url: "", practice_court: false)
  end
end
