class Season < ApplicationRecord
	has_many :slots
	has_many :teams
	has_many :season_locations
	has_many :locations, through: :season_locations
	accepts_nested_attributes_for :locations
	scope :real, -> { where("id>0") }
	self.inheritance_column = "not_sti"

	# return season name - taking start & finish years
	def name
		if self.id == 0	# fake season for all events/teams
			cad = I18n.t("scope.all")
		else
				cad = self.start_year.to_s
			if self.end_year > self.start_year
				cad = cad + "/" + (self.end_year % 100).to_s
			end
		end
	end

	def start_year
		self.start_date.year.to_i
	end

	def end_year
		self.end_date.year.to_i
	end

	#Search field matching
	def self.search(search)
		if search
			search.to_s.length>0 ? Season.where(["id = ?","#{search.to_s}"]).first : Season.real.last
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

	# returns an ordered array of months
	# for this season
	def months(long)
		d = self.start_date
		r = Array.new
		while d < self.end_date
			if long
				r << [d.strftime("%B"), d.month]
			else
				r << { i: d.month, name: (long ? d.strftime("%B") : d.strftime("%^b")) }
			end
			d = d + 1.month
		end
		r
	end

	# return the latest season registered
	def self.latest
		last_date = Season.maximum('start_date')
		return last_date ? Season.real.where(start_date: last_date).first : nil
	end
end
