class Season < ApplicationRecord
	has_many :training_slots
	has_many :teams
	has_many :season_locations
  has_many :locations, through: :season_locations
	accepts_nested_attributes_for :locations
	scope :real, -> { where("id>0") }
	self.inheritance_column = "not_sti"

	def start_year
		self.name[0..3].to_i
	end

	#Search field matching
	def self.search(search)
		if search
			search.to_s.length>0 ? Season.where(["id = ?","#{search.to_s}"]).first : Season.last
		else
			Season.last
		end
	end

	# elgible locations to train / play
	def eligible_locations
    @locations = Location.real - self.locations
  end
end
