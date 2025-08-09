class CreateSteps < ActiveRecord::Migration[7.2]
	def change
		create_table :steps do |t|
			t.references :drill, null: false, foreign_key: true
			t.integer :order
			t.text :diagram_svg

			t.timestamps
		end

		Drill.find_each do |drill|
			if drill.explanation.present?
				step = Step.create!(drill: drill, order: 1)
				step.explanation = drill.explanation
				step.save!
			end
		end
	end
end
