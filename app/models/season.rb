class Season < ApplicationRecord
	has_many :training_slots
	has_many :teams

	def start_year
		self.name[0..3].to_i
	end
end
