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
	def to_s
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
		if self.person.exists? # check if it exists in database
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
			search.length>0 ? Player.where(person_id: Person.where(["(id > 0) AND (name LIKE ? OR nick like ?)","%#{search}%","%#{search}%"]).order(:birthday)) : Player.real
		else
			Player.real
		end
	end

	# to import from excel
	def self.import(file)
		xlsx = Roo::Excelx.new(file.tempfile)
		xlsx.each_row_streaming(offset: 1, pad_cells: true) do |row|
			if row.empty?	# stop parsing if row is empty
				return
			else
				j = self.new(number: row[0].value.to_s, active: row[7].value)
				j.build_person
				j.person.name = row[3].value.to_s
				j.person.surname = row[4].value.to_s
				unless j.is_duplicate? # only if not a duplicate
					if j.person.player_id == nil # new person
						j.person.coach_id  = 0
						j.person.player_id = 0
						j.person.save	# Save and link
					end
				end
				j.person.dni      = j.read_field(row[1], j.person.dni, "S.DNI/NIE")
				j.person.nick     = j.read_field(row[2], j.person.nick, "")
				j.person.birthday = j.read_field(row[5], j.person.birthday, Date.today.to_s)
				j.person.female   = j.read_field(row[6], j.person.female, false)
				j.active	  = j.read_field(row[7], j.active, false)
				j.save
				if j.person.player_id != j.id
					j.person.player_id = j.id
					j.person.save
				end
			end
		end
	end
end
