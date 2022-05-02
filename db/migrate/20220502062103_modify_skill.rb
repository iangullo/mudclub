class ModifySkill < ActiveRecord::Migration[6.1]
  def change
    rename_column :skills, :name, :concept
  end
end
