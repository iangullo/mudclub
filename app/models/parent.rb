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
# Manage parents of underage players
class Parent < ApplicationRecord
	before_destroy :unlink
	belongs_to :person
	has_and_belongs_to_many :players
	accepts_nested_attributes_for :person, update_only: true
	scope :real, -> { where("id>0") }
	scope :active, -> { where("active = true") }
	self.inheritance_column = "not_sti"

	# Just list person's full name
	def to_s
		self.person ? self.person.to_s : I18n.t("person.single")
	end

	def name
		self.s_name
	end

	#short name for form viewing
	def s_name
		self.person ? self.person.s_name : I18n.t("person.show")
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

	# ensures a person is well bound to the Parent - expects both to be persisted
	def clean_bind
		self.person_id = self.person.id if self.person_id != self.person.id
		self.save if self.changed?
		self.person.bind_parent(o_class: "Parent", o_id: self.id)
	end

	# rebuild Parent data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(f_data)
		p_data = f_data[:person_attributes]
		if self.person_id.to_i==0 # not bound to a person yet?
			self.person = p_data[:id].to_i > 0 ? Person.find(p_data[:id].to_i) : self.build_person
		else # person is linked, get it
			self.person.reload
		end
		self.person.rebuild(p_data) # rebuild from passed data
		self.person.parent_id  = self.id if self.id
		self.person.save if self.person.changed?
		self.person_id = self.person.id
	end


	# Attempts to fetch a Parent (or creates a new one)
	# using the hash of fields received.
	def self.fetch(f_data)
		res = f_data[:id].to_i > 0 ? Parent.find_by(id: f_data[:id].to_i) : Parent.new
		res.rebuild(f_data)
		res
	end

	# creates a new 'empty' parent to be used in Nested Forms.
	def self.create_new
		res = Parent.new
		res.build_person
	end

	private
		# cleanup association of dependent objects
		def unlink
			self.players.delete_all
			if self.person	# see what we do with the person
				self.person.update(parent_id: 0)
				self.person.destroy if self.person&.orphan?
			end
		end
end
