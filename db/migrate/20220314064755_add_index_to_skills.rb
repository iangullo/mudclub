class AddIndexToSkills < ActiveRecord::Migration[6.1]
  def change
    add_index :skills, :name
  end
end
