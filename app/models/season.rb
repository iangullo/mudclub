class Season < ApplicationRecord
	has_many :slots
	has_many :teams
	has_many :season_locations
  has_many :locations, through: :season_locations
	accepts_nested_attributes_for :locations
	scope :real, -> { where("id>0") }
	self.inheritance_column = "not_sti"

	def start_year
		self.start_date.year.to_i
	end

	def end_year
		self.end_date.year.to_i
	end

	#Search field matching
	def self.search(search)
		if search
			search.to_s.length>0 ? Season.where(["id = ?","#{search.to_s}"]).first : Season.last
		else
			Season.last
		end
	end

	#Search field matching
	def self.search_date(s_date)
		res = nil
		if s_date
			sd = s_date.to_date	# ensure type conversion
			if sd
				Season.real.each { |season|
					return season if sd.between?(season.start_date, season.end_date)
				}
			end
		end
		return res
	end

	# elgible locations to train / play
	def eligible_locations
    @locations = Location.real - self.locations
  end

	# returns an orderd array of months
	# for this season
	def months
		d = self.start_date
		r = Array.new
		while d < self.end_date
			r << { i: d.month, name: d.strftime("%^b") }
			d = d + 1.month
		end
		r
	end
end
