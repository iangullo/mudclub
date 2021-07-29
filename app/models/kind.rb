class Kind < ApplicationRecord
	has_many :drills
	before_save { self.name = self.name.mb_chars.titleize }
end
