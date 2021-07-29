class Location < ApplicationRecord
	scope :practice, -> { where("practice_court = true") }
end
