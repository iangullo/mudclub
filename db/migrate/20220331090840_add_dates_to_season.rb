class AddDatesToSeason < ActiveRecord::Migration[6.1]
  def change
    add_column :seasons, :start, :date
    add_column :seasons, :end, :date
  end
end
