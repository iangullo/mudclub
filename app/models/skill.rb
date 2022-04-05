class Skill < ApplicationRecord
	has_and_belongs_to_many :drills
	self.inheritance_column = "not_sti"

	# search database for a Skill with matching name
	def self.search(search)
		if search
			if search.length > 0
				return Skill.where("unaccent(name) ILIKE unaccent(?)","%#{search}%")
			else
			 	return Skill.all.order(:kind)
		 	end
	 	else
			return Skill.all.order(:kind)
		end
	end

	def self.search_drills(search)
		skills = self.search(search)
		res    = Drill.none
		if skills
			unless skills.empty?
				skills.each {	|s|	res = res  and s.drills }
			end
		end
		res
	end
end
