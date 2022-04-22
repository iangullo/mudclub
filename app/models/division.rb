class Division < ApplicationRecord
	has_many :teams
	scope :real, -> { where("id>0") }
end
