class Player < ApplicationRecord
	has_and_belongs_to_many :teams
	has_one :person
	has_one_attached :avatar
	accepts_nested_attributes_for :person, update_only: true
	scope :real, -> { where("id>0") }
	scope :active, -> { where("active = true") }
	scope :female, -> { where("female = true") }
	scope :male, -> { where("female = false") }
	self.inheritance_column = "not_sti"
    	
	# Just list person's full name
	def fullname
		person ? person.to_s : "Nuevo"
	end
	
	# String with number, name & age
	def num_name_age
		number.to_s.rjust(7," ") + "-" + self.fullname + " (" + self.person.age.to_s + ")"
	end
	
	def female
		self.person.female
	end
	
	# check if associated person exists in database already
	# reloads person if it does
	def is_duplicate?
		p_id = self.person.exists? # check if it exists in database
		if p_id # found person
			self.person_id = p_id
			self.person.id = p_id
			self.person.reload	# reload data
			if self.person.player_id > 0 # player already exists
				true
			else	# found but mapped to dummy placeholder person
				false
			end
		else	# not found
			false
		end
	end
	
	def picture
		self.avatar.attached? ? self.avatar : "player.png"
	end
	
	#Search field matching
	def self.search(search)
		if search 
			Player.where(person_id: Person.where(["name LIKE ? OR nick like ?","%#{search}%","%#{search}%"]).order(:birthday))
		else
			Player.none
		end
	end 

	# to import from excel
	def self.import(file)
		xlsx = Roo::Excelx.new(file.tempfile)
		xlsx.each_row_streaming(offset: 1) do |row|
			j = self.new(number: row[0].value.to_s, active: row[6].value)
			j.build_person
			j.person.name = row[2].value.to_s
			j.person.surname = row[3].value.to_s
			j.active = row[6].value
			unless j.is_duplicate? # only if not a duplicate
				j.person.nick = row[1].value.to_s
				j.person.birthday = row[4].value
				j.person.female = row[5].value				
				if j.person.player_id == nil # new person
					j.person.coach_id = 0
					j.person.player_id = 0
				end
				j.person.save
				j.person_id = j.person.id
				j.save
				if j.person.player_id != j.id
					j.person.player_id = j.id
					j.person.save
				end
			end
		end
	end
end
