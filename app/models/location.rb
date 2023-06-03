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
class Location < ApplicationRecord
	before_destroy :unlink
	scope :practice, -> { where("practice_court = true") }
	scope :home, -> { where("id > 0 and practice_court = false") }
	scope :real, -> { where("id > 0") }
	has_many :teams
	has_many :slots, dependent: :destroy
	has_many :events
	has_many :season_locations, dependent: :destroy
	has_many :seasons, through: :season_locations
	accepts_nested_attributes_for :seasons
	self.inheritance_column = "not_sti"

	def to_s
		self.id==0 ? I18n.t("location.none") : self.name
	end

	# checks if it exists in the collection before adding it
	# returns: reloads self if it exists in the database already
	# 	   'nil' if it needs to be created.
	def exists?
		p = Location.where(name: self.name)
		if p.try(:size)==1
			self.id = p.first.id
			self.reload
		else
			nil
		end
	end

	#Search field matching
	def self.search(search)
		if search
			search.length>0 ? Location.where("unaccent(name) ILIKE unaccent(?)","%#{search}%") : Location.real
		else
			Location.real
		end
	end

	# rebuild @location from raw hash returned by a form
	def rebuild(l_data)
		self.name           = l_data[:name]
		self.exists? # reload from database
		self.gmaps_url      = l_data[:gmaps_url] if l_data[:gmaps_url].length > 0
		self.practice_court = (l_data[:practice_court] == "1")
	end

	private
		# cleanup dependent events, reassigning to 'dummy' location
		def unlink
			self.events.update_all(location_id: 0)
			self.teams.update_all(location_id: 0)
		end
end
