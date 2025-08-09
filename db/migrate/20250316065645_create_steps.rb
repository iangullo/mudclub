# db/migrate/20250501173613_create_steps_with_svgdata.rb
class CreateStepsWithSvgdata < ActiveRecord::Migration[8.0]
	def change
		create_table :steps do |t|
			t.references :drill, null: false, foreign_key: true
			t.integer :order
			t.jsonb :svgdata  # Directly use final column name and type
			t.timestamps
		end

		# Data migration for drill explanations
		Drill.reset_column_information
		Step.reset_column_information

		Drill.find_each do |drill|
			next unless drill.explanation.present?

			# Handle both string and rich text explanations
			content = if drill.explanation.respond_to?(:body)
									drill.explanation.body
								else
									drill.explanation
								end

			step = Step.create!(drill: drill, order: 1)
			step.explanation = content
			step.save!
		end
	end
end