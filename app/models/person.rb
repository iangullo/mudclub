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
class Person < ApplicationRecord
	include PersonDataManagement
	#validates :email, uniqueness: true
	#validates :dni, uniqueness: true
	before_destroy :unlink
	belongs_to :coach
	belongs_to :player
	belongs_to :user
	belongs_to :parent
	has_one_attached :avatar
	accepts_nested_attributes_for :player
	accepts_nested_attributes_for :coach
	accepts_nested_attributes_for :user
	validates :name, :surname, presence: true
	scope :real, -> { where("id>0") }
	scope :lost, -> {	where("(player_id=0) and (coach_id=0) and (user_id=0) and (parent_id=0)") }
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
		res.length > 0 ? res : I18n.t("person.single")
	end

	# finds a person in the database based on id, email, dni, name & surname
	# returns: reloads person if it exists in the database already or
	# 	   'nil' if it not found.
	def self.fetch(f_data)
		# Try to find by id if present
		id = f_data[:id].presence.to_i
		p_aux = Person.find_by(id:) if id > 0

		# Try to find by dni if present
		p_aux = Person.find_by(dni: f_data[:dni]) if !p_aux && (dni = f_data[:dni].presence)

		# Try to find by email if present
		p_aux = Person.find_by(email: f_data[:email]) if !p_aux && (email = f_data[:email].presence)

		unless p_aux	# last resort: attempt to find by name+surname
			name    = f_data[:name].presence
			surname = f_data[:surname].presence
			if name and surname
				p_aux = Person.where("unaccent(name) ILIKE unaccent(?) AND unaccent(surname) ILIKE unaccent(?)", name, surname).take
			end
		end
		p_aux
	end

	# rebuild Person data from raw input (as hash) given by a form submittal
	# avoids creating duplicates
	def rebuild(f_data)
		p_aux = Person.fetch(f_data)
		if p_aux&.id != self.id	# re-load self as existing Person
			self.id = p_aux.id
			self.reload
		end
		self.dni       = f_data[:dni].presence || self.dni || ""
		self.email     = f_data[:email].presence || self.email || ""
		self.name      = f_data[:name].presence || self.name
		self.surname   = f_data[:surname].presence || self.surname
		self.address   = f_data[:address].presence || self.address
		self.birthday  = f_data[:birthday].presence || self.birthday
		self.nick      = f_data[:nick].presence || self.nick
		self.female    = to_boolean(f_data[:female])
		self.phone     = Phonelib.parse(f_data[:phone].delete(' ')).international.to_s if f_data[:phone].presence
		self.coach_id  = 0 unless self.coach_id.to_i > 0
		self.player_id = 0 unless self.player_id.to_i > 0
		self.parent_id = 0 unless self.parent_id.to_i > 0
		self.user_id   = 0 unless self.user_id.to_i > 0
		return self
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

	# personal logo
	def picture
		self.avatar.attached? ? self.avatar : "person.svg"
	end

	# used for clublogo (Person(id: 0))
	def logo
		self.avatar.attached? ? self.avatar : "mudclub.svg"
	end

	# to import from excel
	def self.import(file)
		xlsx = Roo::Excelx.new(file.tempfile)
		xlsx.each_row_streaming(offset: 1, pad_cells: true) do |row|
			if row.empty?	# stop parsing if row is empty
				return
			else
				p = Person.fetch({name: row[2].value, surname: row[3].value})
				if p.nil?
					p = self.new(
						name:      row[2].value.to_s.strip,
						surname:   row[3].value.to_s.strip,
						coach_id:  0,
						parent_id: 0,
						player_id: 0,
						user_id:   0
					)
				end
				p.import_person_row(
					[
						row[0], # dni
						row[2], # name
						row[3], # surname
						row[1],	# nick
						row[4],	# birthday
						row[6],	# address
						row[7],	# email
						row[8], # phone
						row[5]	# female
					]
				)
				p&.save
			end
		end
	end

	#Search field matching
	def self.search(search)
		if search
			search.length>0 ? Person.where(["(id > 0) AND (unaccent(name) ILIKE unaccent(?) OR unaccent(nick) ILIKE unaccent(?) OR unaccent(surname) ILIKE unaccent(?))","%#{search}%","%#{search}%","%#{search}%"]) : Person.none
		else
			Person.none
		end
	end

	# return if person is orphaned from any dependent objects
	def orphan?
		(self.player_id.to_i==0) and (self.coach_id.to_i==0) and (self.user_id.to_i==0) and (self.parent_id.to_i==0)
	end

	private
		# unlink/delete dependent objects
		def unlink
			gen_unlink(:coach) if self.coach_id > 0	# delete associated coach
			gen_unlink(:player) if self.player_id > 0	# delete associated player
			gen_unlink(:user) if self.user_id > 0	# delete associated user
			gen_unlink(:parent) if self.parent_id > 0	# delete associated user
			UserAction.prune("/people/#{self.id}")
		end

		# called by unlink using either :coach, :player or :user as arguments
		def gen_unlink(kind)
			dep = self.send(kind.to_sym)
			if dep
				self.update!("#{kind}_id".to_sym 0)
				dep.destroy
			end
		end
end
