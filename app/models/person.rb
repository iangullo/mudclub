# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
	include PgSearch::Model
	before_destroy :unlink
	before_save { self.name = self.name ? self.name.mb_chars.titleize : ""}
	before_save { self.surname = self.surname ? self.surname.mb_chars.titleize : ""}
	belongs_to :coach, optional: true
	belongs_to :player, optional: true
	belongs_to :user, optional: true
	belongs_to :parent, optional: true
	accepts_nested_attributes_for :coach
	accepts_nested_attributes_for :player
	accepts_nested_attributes_for :user
	has_one_attached :avatar
	has_one_attached :id_front
	has_one_attached :id_back
	pg_search_scope :search,
		against: [:nick, :name, :surname],
		ignoring: :accents,
		using: { tsearch: {prefix: true} }
	scope :real, -> { where("id>0") }
	scope :lost, -> {	where("(player_id=0) and (coach_id=0) and (user_id=0) and (parent_id=0)") }
	validates :email, uniqueness: { allow_nil: true }
	validates :dni, uniqueness: { allow_nil: true }
	validates :phone, uniqueness: { allow_nil: true }
	validates :name, :surname, presence: true
	self.inheritance_column = "not_sti"

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

	# wrapper to display birthday strings
	def birthstring
		self.birthday&.strftime("%d/%m/%Y")
	end

	# returns a hash of icon & label to mark whether a
	# Person has attached id pictures (front && back)
	def idpic_content
		label = self.dni
		if self.idpics_attached?
			found = true
			icon  = "id_front.svg"
			tip   = I18n.t("person.pics_found")
		else
			found = self.id_front.attached? || self.id_back.attached?
			icon  = "id_front-no.svg"
			tip   = I18n.t("person.pics_missing")
		end
		{found:, icon:, label:, tip:}
	end

	# checks whether a Person has attached id pictures (front && back)
	def idpics_attached?
		self.id_front.attached? && self.id_back.attached?
	end

	# used for clublogo (Person(id: 0)) - DEPRECATED
	def logo
		self.avatar.attached? ? self.avatar : "mudclub.svg"
	end

	# extended modified to acount for changed parents or avatar
	def modified?
		self.changed? || @attachment_changed
	end

	# return if person is orphaned from any dependent objects
	def orphan?
		self&.id.to_i > 0 && (self.player_id.nil?) && (self.coach_id.nil?) && (self.user_id.nil?) && (self.parent_id.nil?)
	end

	# hopefully return self...
	def person
		self
	end

	# personal logo
	def picture
		self.avatar.attached? ? self.avatar : "person.svg"
	end

	# rebuild Person data from raw input (as hash) given by a form submittal
	def rebuild(f_data)
		self.dni       = f_data[:dni].presence || self.dni
		self.email     = f_data[:email].presence || self.email
		self.name      = f_data[:name].presence || self.name
		self.surname   = f_data[:surname].presence || self.surname
		self.address   = f_data[:address].presence || self.address
		self.birthday  = f_data[:birthday].presence || self.birthday
		self.nick      = f_data[:nick].presence || self.nick
		self.female    = to_boolean(f_data[:female])
		self.phone     = parse_phone(f_data[:phone]) if f_data[:phone].presence
		self.coach_id  = nil unless self.coach_id.to_i > 0
		self.player_id = nil unless self.player_id.to_i > 0
		self.parent_id = nil unless self.parent_id.to_i > 0
		self.user_id   = nil unless self.user_id.to_i > 0
		self.update_attachment("avatar", f_data[:avatar]) if f_data[:avatar].present?
		self.update_attachment("id_front", f_data[:id_front]) if f_data[:id_front].present?
		self.update_attachment("id_back", f_data[:id_back]) if f_data[:id_back].present?
		return self
	end

	#short name for form viewing
	def s_name
		res = "#{self.to_s(false)} #{self.surname&.split&.first}"
		res.present? ? res : I18n.t("person.single")
	end

	def to_s(long=true)
		aux = self.nick.presence || self.name.to_s
		aux += " #{self.surname.to_s}" if long
		aux
	end

	# finds a person in the database based on id, email, dni, name & surname
	# returns: reloads person if it exists in the database already or
	# 	   a freshly created person(id: nil) if it not found.
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
		p_aux ||= Person.new
		p_aux.rebuild(f_data)
		p_aux
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

	private
		# called by unlink using either :coach, :player or :user as arguments
		def gen_unlink(kind)
			if (dep = self.send(kind.to_sym))
				self.update!("#{kind}_id".to_sym nil)
				dep.destroy
			end
		end

		# unlink/delete dependent objects
		def unlink
			self.avatar.purge if self.try(:avatar)&.attached?
			gen_unlink(:coach) if self.coach_id.to_i > 0	# avoid deleting placeholders
			gen_unlink(:player) if self.player_id.to_i > 0
			gen_unlink(:user) if self.user_id
			gen_unlink(:parent) if self.parent_id
			UserAction.prune("/people/#{self.id}")
		end
end
