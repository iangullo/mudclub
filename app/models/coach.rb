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
	def fullname
		person ? person.to_s : "Nuevo"
	end

	# check if associated person exists in database already
	# reloads person if it does
	def is_duplicate?
		p_id = self.person.exists? # check if it exists in database
		if p_id # found person
			self.person.id = p_id
			self.person_id = p_id
			self.person.reload	# reload data
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
			Coach.where(person_id: Person.where(["(id > 0) AND (name LIKE ? OR nick like ?)","%#{search}%","%#{search}%"]).order(:birthday))
		else
			Coach.none
		end
	end
end
