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
		self.person ? self.person.to_s : "Nuevo"
	end

	#short name for form viewing
	def s_name
		if self.person
			if self.person.nick
				self.person.nick.length >  0 ? self.person.nick : self.person.name
			else
				self.person.name
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
		self.avatar.attached? ? self.avatar : "coach.svg"
	end

	#Search field matching
	def self.search(search)
		if search
      search.length>0 ? Coach.where(person_id: Person.where(["(id > 0) AND (name LIKE ? OR nick like ?)","%#{search}%","%#{search}%"]).order(:birthday)) : Coach.where(person_id: Person.real.order(:birthday))
		else
      Coach.none
		end
	end

	# to import from excel
	def self.import(file)
		xlsx = Roo::Excelx.new(file.tempfile)
		xlsx.each_row_streaming(offset: 1, pad_cells: true) do |row|
			if row.empty?	# stop parsing if row is empty
				return
			else
				c = self.new(active: row[7].value)
				c.build_person
				c.person.name = row[2].value.to_s
				c.person.surname = row[3].value.to_s
				unless c.is_duplicate? # only if not a duplicate
					if c.person.coach_id == nil # new person
						c.person.coach_id  = 0
						c.person.player_id = 0
						c.person.save	# Save and link
					end
				end
				c.person.dni      = c.read_field(row[0], c.person.dni, "S.DNI/NIE")
				c.person.nick     = c.read_field(row[1], c.person.nick, "")
				c.person.birthday = c.read_field(row[4], c.person.birthday, Date.today.to_s)
				c.person.email		= c.read_field(row[5], c.person.email, "")
				c.person.phone		= c.read_field(Phonelib.parse(row[6]).international, c.person.phone, "")
				c.active	  			= c.read_field(row[7], c.active, false)
				c.save
				c.clean_bind	# ensure person is bound
			end
		end
	end

	#ensures a person is well bound to the coach
	def clean_bind
		if self.person_id != self.person.id
			self.person_id = self.person.id
			self.save
		end
		if self.person.coach_id != self.id
			self.person.coach_id = self.id
			self.person.save
		end
	end
end
