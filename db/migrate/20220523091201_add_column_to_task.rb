class AddColumnToTask < ActiveRecord::Migration[6.1]
  def change
    add_column :tasks, :remarks, :string
  end
end
