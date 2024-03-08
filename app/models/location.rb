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
class Location < ApplicationRecord
	before_destroy :unlink
	scope :practice, -> { where("practice_court = true") }
	scope :home, -> { where("id > 0 and practice_court = false") }
	scope :real, -> { where("id > 0") }
	has_many :club_locations, dependent: :destroy
	has_many :clubs, through: :club_locations
	has_many :events
	has_many :slots, dependent: :destroy
	pg_search_scope :search_by_name,
		against: :name,
		ignoring: :accents,
		using: { tsearch: {prefix: true} }
	self.inheritance_column = "not_sti"

	def to_s
		self.id==0 ? I18n.t("location.none") : self.name
	end

	# checks if it exists in the collection before adding it
	# returns: reloads self if it exists in the database already
	# 	   'nil' if it needs to be created.
	def exists?
		p = Location.where(name: self.name)
		if p&.size==1
			self.id = p.first.id
			self.reload
		else
			nil
		end
	end

	#Search field matching
	def self.search(club_id: nil, season_id: nil, name: nil)
		qry = (club_id ?  Location.where(id: ClubLocation.where(club_id:).pluck(:location_id)) : Location.real)
		if season_id.present?
			qry = qry.where(id: SeasonLocation.where(season_id:).pluck(:location_id))
		end
		qry = qry.search_by_name(name) if name.present?

		qry.order(:name)
	end
		
	# rebuild @location from raw hash returned by a form
	def rebuild(f_data)
		self.name           = f_data[:name]
		self.exists? # reload from database
		self.gmaps_url      = f_data[:gmaps_url] if f_data[:gmaps_url].length > 0
		self.practice_court = (f_data[:practice_court] == "1")
	end

	# return teams that have this location as homecourt
	def teams
		Team.where(homecourt_id: self.id)
	end

	private
		# cleanup dependent events, reassigning to 'dummy' location
		def unlink
			self.events.update_all(location_id: 0)
			self.teams.update_all(homecourt_id: 0)
			UserAction.prune("/locations/#{self.id}")
		end
end
