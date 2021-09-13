class Person < ApplicationRecord
	belongs_to :coach
	belongs_to :player
	accepts_nested_attributes_for :player
	accepts_nested_attributes_for :coach
	validates :name, :surname, presence: true
	scope :real, -> { where("id>0") }
	before_save { self.nick = self.nick ? self.nick.mb_chars.titleize : ""}
	before_save { self.name = self.name ? self.name.mb_chars.titleize : ""}
	before_save { self.surname = self.surname ? self.surname.mb_chars.titleize : ""}
	self.inheritance_column = "not_sti"

	def to_s
		if self.nick and self.nick.length > 0
			aux = self.nick.to_s
		else
			aux = self.name.to_s
		end
		aux += " " + self.surname.to_s
	end

	# checks if it exists in the collection before adding it
	# returns: 'id' if it exists in the database already
	# 		   'nil' if it needs to be created.
	def exists?
		aux = Person.where(name: self.name, surname: self.surname).first
		aux ? aux.id : nil
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
				if p.exists?
					p.reload
				else
					p.player_id = 0
					p.coach_id = 0
				end
				p.dni      = read_field(row[0], p.dni, "S.DNI/NIE")
				p.nick     = read_field(row[1], p.nick, "")
				p.birthday = read_field(row[4], p.birthday, Date.today.to_s)
				p.female   = read_field(row[5], p.female, false)
				p.save
			end
		end
	end

	#Search field matching
	def self.search(search)
		if search
			search.length>0 ? Person.where(["(id > 0) AND (name LIKE ? OR nick like ?)","%#{search}%","%#{search}%"]) : Person.all
		else
			Person.none
		end
	end

	private

	# read new field value, keep old value if empty & possible
	def read_field(dat_value, old_value, def_value)
		if dat_value	# we read & assign
			read_field = datum.value.to_s
		else	# assign default if no old value exists
			read_field = "def_value" unless old_value
		end
	end
end
