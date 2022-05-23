class Skill < ApplicationRecord
	has_and_belongs_to_many :drills
	scope :real, -> { where("id>0") }
	scope :search, -> (s_s) { where("unaccent(concept) ILIKE unaccent(?)","%#{s_s}%") }

end
