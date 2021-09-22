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
	# returns: reloads self if it exists in the database already
	# 	   'nil' if it needs to be created.
	def exists?
		p = Person.where(name: self.name, surname: self.surname).first
		if p
			self.id = p.id
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
				p = self.new(name: row[1].value.to_s, surname: row[2].value.to_s)
				unless p.exists?
					p.player_id = 0
					p.coach_id = 0
				end
				p.nick     = p.read_field(row[0], p.nick, "")
				p.birthday = p.read_field(row[3], p.birthday, Date.today.to_s)
				p.female   = p.read_field(row[4], p.female, false)
				p.save
			end
		end
	end

	#Search field matching
	def self.search(search)
		if search
			search.length>0 ? Person.where(["(id > 0) AND (name LIKE ? OR nick like ?)","%#{search}%","%#{search}%"]) : Person.real
		else
			Person.none
		end
	end
end
