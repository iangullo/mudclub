class Skill < ApplicationRecord
	has_and_belongs_to_many :drills
	scope :search, -> (s_s) { where("unaccent(name) ILIKE unaccent(?)","%#{s_s}%") }

end
