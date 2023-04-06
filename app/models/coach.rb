# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
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
		self.person ? self.person.to_s : I18n.t("coach.single")
	end

	def name
		self. s_name
	end

	#short name for form viewing
	def s_name
		self.person ? self.person.s_name : I18n.t("coach.show")
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
		self.avatar.attached? ? self.avatar : self.person.avatar.attached? ? self.person.avatar : "coach.svg"
	end

	#Search field matching
	def self.search(search)
		if search
			if search.length>0
				Coach.where(person_id: Person.where(["(id > 0) AND (unaccent(name) ILIKE unaccent(?) OR unaccent(nick) ILIKE unaccent(?) OR unaccent(surname) ILIKE unaccent(?) )","%#{search}%","%#{search}%","%#{search}%"]).order(:birthday))
			else
				Coach.none
			end
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
				c.person.dni      = c.read_field(row[0], c.person.dni, I18n.t("person.pid"))
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

	# ensures a person is well bound to the coach - expects both to be persisted
	def clean_bind
		self.person_id = self.person.id if self.person_id != self.person.id
		self.save if self.changed?
		self.person.bind_parent(o_class: "Coach", o_id: self.id)
	end

	# rebuild Coach data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(c_data)
		p_data = c_data[:person_attributes]
		if self.person_id==0 # not bound to a person yet?
			self.person = p_data[:id].to_i > 0 ? Person.find(p_data[:id].to_i) : self.build_person
		else # person is linked, get it
			self.person.reload
		end
		self.person.rebuild(p_data) # rebuild from passed data
		self.person.coach_id  = self.id if self.id
		self.person.save unless self.person.id
		self.person_id = self.person.id
		self.active    = c_data[:active]
	end
end
