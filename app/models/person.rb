class Person < ApplicationRecord
	belongs_to :coach
	belongs_to :player
	belongs_to :user
	has_one_attached :avatar
	accepts_nested_attributes_for :player
	accepts_nested_attributes_for :coach
	accepts_nested_attributes_for :user
	validates :name, :surname, presence: true
	scope :real, -> { where("id>0") }
	before_save { self.name = self.name ? self.name.mb_chars.titleize : ""}
	before_save { self.surname = self.surname ? self.surname.mb_chars.titleize : ""}
	self.inheritance_column = "not_sti"

	def to_s(long=true)
		if self.nick and self.nick.length > 0
			aux = self.nick.to_s
		else
			aux = self.name.to_s
		end
		aux += " " + self.surname.to_s if long
		aux
	end

	#short name for form viewing
	def s_name
		res = self.to_s(false)
		res.length > 0 ? res : I18n.t(:l_per_show)
	end

	# checks if it exists in the collection before adding it
	# returns: reloads self if it exists in the database already
	# 	   'nil' if it needs to be created.
	def exists?
		p = Person.where(dni: self.dni).or(Person.where(email: self.email)).or(Person.where(name: self.name, surname: self.surname))
		if p.try(:size)==1
			self.id = p.first.id
			self.reload
		else
			nil
		end
	end

	# calculate age
	def age
		if self.birthday
			now = Time.now.utc.to_date
			bday=self.birthday
			now.year - bday.year - ((now.month > bday.month || (now.month == bday.month && now.day >= bday.day)) ? 0 : 1)
		else
			0
		end
	end

	def birthyear
		self.birthday.year
	end

	# to import from excel
	def self.import(file)
		xlsx = Roo::Excelx.new(file.tempfile)
		xlsx.each_row_streaming(offset: 1, pad_cells: true) do |row|
			if row.empty?	# stop parsing if row is empty
				return
			else
				p = self.new(name: row[2].value.to_s, surname: row[3].value.to_s)
				unless p.exists?
					p.player_id = 0
					p.coach_id = 0
				end
				p.dni      = p.read_field(row[0], p.dni, I18n.t(:h_id))
				p.nick     = p.read_field(row[1], p.nick, "")
				p.birthday = p.read_field(row[4], p.birthday, Date.today.to_s)
				p.female   = p.read_field(row[5], p.female, false)
				p.email		 = p.read_field(row[6], p.email, "")
				p.phone		 = p.read_field(Phonelib.parse(row[7]).international, p.phone, "")
				p.save
			end
		end
	end

	def picture
		self.avatar.attached? ? self.avatar : "person.svg"
	end

	def logo
		self.avatar.attached? ? self.avatar : "clublogo.svg"
	end

	#Search field matching
	def self.search(search)
		if search
			search.length>0 ? Person.where(["(id > 0) AND (unaccent(name) ILIKE unaccent(?) OR unaccent(nick) ILIKE unaccent(?) OR unaccent(surname) ILIKE unaccent(?))","%#{search}%","%#{search}%","%#{search}%"]) : Person.none
		else
			Person.none
		end
	end
end
