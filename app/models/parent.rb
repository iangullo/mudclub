# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
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
	include PersonDataManagement
	before_destroy :unlink
	belongs_to :person
	has_and_belongs_to_many :players
	accepts_nested_attributes_for :person, update_only: true
	scope :real, -> { where("id>0") }
	scope :active, -> { where("active = true") }
	self.inheritance_column = "not_sti"

	def name
		self.s_name
	end

	# rebuild Parent data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(f_data)
		self.rebuild_obj_person(f_data)
	end

	#short name for form viewing
	def s_name
		self.person&.s_name || I18n.t("person.show")
	end

	# wrapper to get teams of children
	def team_list
		res = []
		self.players.each { |player| res = (res + player.team_list).uniq }
		res.sort_by{ |team| team.season.start_date }.reverse
	end

	# Just list person's full name
	def to_s
		self.person&.to_s || I18n.t("person.single")
	end

	# creates a new 'empty' parent to be used in Nested Forms.
	def self.create_new
		res = Parent.new
		res.build_person
		res
	end

	# atempt to fetch a Parent using form input hash
	def self.fetch(f_data)
		self.new.fetch_obj(f_data)
	end

	private
		# cleanup association of dependent objects
		def unlink
			self.players.delete_all
			self.scrub_person
		end
end
