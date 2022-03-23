class Location < ApplicationRecord
	scope :practice, -> { where("practice_court = true") }
	scope :home, -> { where("practice_court = false") }
	scope :real, -> { where("id > 0") }
	before_save { self.name = self.name ? self.name.mb_chars.titleize : ""}

	# checks if it exists in the collection before adding it
	# returns: reloads self if it exists in the database already
	# 	   'nil' if it needs to be created.
	def exists?
		p = Location.where(name: self.name)
		if p.try(:size)==1
			self.id = p.first.id
			self.reload
		else
			nil
		end
	end
end
