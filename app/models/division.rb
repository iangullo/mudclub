class Division < ApplicationRecord
	has_many :teams
	scope :real, -> { where("id>0") }

	def to_s
		self.name
	end
end
