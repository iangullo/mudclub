class CreateCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :sex
      t.integer :min_years
      t.integer :max_years

      t.timestamps
    end
    Category.create(id: 0, name: "None", sex: "Mixed", min_years: 5, max_years: 99)
  end
end
