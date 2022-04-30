class Kind < ApplicationRecord
	has_many :drills
	before_save { self.name = self.name.mb_chars.titleize }
	scope :search, -> (s_k) { where("unaccent(name) ILIKE unaccent(?)","%#{s_k}%") }

end
