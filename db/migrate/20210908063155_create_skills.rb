class CreateSkills < ActiveRecord::Migration[6.1]
  def change
    create_table :skills do |t|
      t.string :name

      t.timestamps
    end
    Skill.create(id: 0, name: "")
  end
end
