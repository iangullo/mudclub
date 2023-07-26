class AddPeriodToStat < ActiveRecord::Migration[7.0]
  def change
    add_column :stats, :period, :integer, default: 0
  end
end
