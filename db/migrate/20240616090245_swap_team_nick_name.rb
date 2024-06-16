class SwapTeamNickName < ActiveRecord::Migration[7.0]
  def change
    change_table(:teams) do |t|
      t.rename(:nick, :n_name)
      t.rename(:name, :nick)
      t.rename(:n_name, :name)
    end
  end
end
