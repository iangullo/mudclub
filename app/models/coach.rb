class Coach < ApplicationRecord
	has_many :drills
	has_and_belongs_to_many :teams
	has_one :person
	has_one_attached :avatar
	accepts_nested_attributes_for :person, update_only: true
	scope :real, -> { where("id>0") }
	scope :active, -> { where("active = true") }
	self.inheritance_column = "not_sti"

	# Just list person's full name
	def to_s
		person ? person.to_s : "Nuevo"
	end

	def s_name
		if person
			if person.nick
				person.nick.length >  0 ? person.nick : person.name
			else
				person.name
			end
		else
			"Nuevo"
		end
	end

	# check if associated person exists in database already
	# reloads person if it does
	def is_duplicate?
		if self.person.exists? # check if it exists in database
			if self.person.coach_id > 0 # coach already exists
				true
			else	# found but mapped to dummy placeholder person
				false
			end
		else	# not found
			false
		end
	end

	def picture
		self.avatar.attached? ? self.avatar : "coach.png"
	end

	#Search field matching
	def self.search(search)
		if search
      search.length>0 ? Coach.where(person_id: Person.where(["(id > 0) AND (name LIKE ? OR nick like ?)","%#{search}%","%#{search}%"]).order(:birthday)) : Coach.where(person_id: Person.real.order(:birthday))
		else
      Coach.none
		end
	end
end
