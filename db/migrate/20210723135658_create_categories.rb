class CreateCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :sex
      t.integer :min_years
      t.integer :max_years

      t.timestamps
    end
  end
end
