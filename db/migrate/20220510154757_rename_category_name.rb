class RenameCategoryName < ActiveRecord::Migration[6.1]
  def change
    rename_column :categories, :name, :age_group
  end
end
