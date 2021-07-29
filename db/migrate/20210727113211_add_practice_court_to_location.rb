class AddPracticeCourtToLocation < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :practice_court, :boolean
  end
end
