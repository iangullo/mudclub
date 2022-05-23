class Kind < ApplicationRecord
	has_many :drills
	before_save { self.name = self.name.mb_chars.titleize }
	scope :real, -> { where("id>0") }
	scope :search, -> (s_k) { where("unaccent(name) ILIKE unaccent(?)","%#{s_k}%") }

end
