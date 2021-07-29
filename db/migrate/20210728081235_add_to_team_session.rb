class AddToTeamSession < ActiveRecord::Migration[6.1]
  def change
    add_reference :training_sessions, :location
    add_column :training_sessions, :start, :time
    add_column :training_sessions, :duration, :integer
  end
end
