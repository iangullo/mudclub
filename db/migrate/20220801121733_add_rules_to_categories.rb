class AddRulesToCategories < ActiveRecord::Migration[7.0]
  def change
    add_column :categories, :rules, :integer, default: 0
  end
end
