class Season < ApplicationRecord
	has_many :training_slots
	has_many :teams
	scope :real, -> { where("id>0") }

	def start_year
		self.name[0..3].to_i
	end
end
