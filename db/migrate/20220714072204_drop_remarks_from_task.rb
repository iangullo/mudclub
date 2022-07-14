class DropRemarksFromTask < ActiveRecord::Migration[7.0]
  def change
    remove_column :tasks, :remarks
  end
end
