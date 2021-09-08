class Category < ApplicationRecord
	scope :real, -> { where("id>0") }

	def to_s
		self.name.to_s + " " + self.sex.to_s
	end
	
	# calculate earliest valid birthday date depending on
	# s_year (season year)
	def youngest(s_year)
		DateTime.new(s_year-self.min_years+1,1,1).to_date
	end
	
	# same for latest valid birthdate
	def oldest(s_year)
		DateTime.new(s_year-self.max_years-1,12,31).to_date
	end
end
