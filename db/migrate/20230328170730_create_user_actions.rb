class CreateUserActions < ActiveRecord::Migration[7.0]
  def change
    create_table :user_actions do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.datetime :performed_at
      t.integer :kind
      t.string :description

      t.timestamps
    end
  end
end
