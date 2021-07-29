class AddTargetsToTraininSession < ActiveRecord::Migration[6.1]
  def change
    add_column :training_sessions, :targets, :string
  end
end
