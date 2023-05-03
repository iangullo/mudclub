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
class Season < ApplicationRecord
	has_many :slots
	has_many :teams
	has_many :season_locations
	has_many :locations, through: :season_locations
	accepts_nested_attributes_for :locations
	scope :real, -> { where("id>0") }
	self.inheritance_column = "not_sti"

	# return season name - taking start & finish years
	def name
		if self.id == 0	# fake season for all events/teams
			cad = I18n.t("scope.all")
		else
			cad = self.start_year.to_s
			if self.end_year > self.start_year
				cad = cad + "/" + (self.end_year % 100).to_s
			end
		end
		cad
	end

	def start_year
		self.start_date.year.to_i
	end

	def end_year
		self.end_date.year.to_i
	end

	#Search field matching
	def self.search(search)
		if search
			search.to_s.length>0 ? Season.where(["id = ?","#{search.to_s}"]).first : Season.real.last
		else
			Season.last
		end
	end

	#Search field matching
	def self.search_date(s_date)
		res = nil
		if s_date
			sd = s_date.to_date	# ensure type conversion
			if sd
				Season.real.each { |season|
					return season if sd.between?(season.start_date, season.end_date)
				}
			end
		end
		return res
	end

	# elgible locations to train / play
	def eligible_locations
		@locations = Location.real - self.locations
	end

	# returns an ordered array of months
	# for this season
	def months(long)
		d = self.start_date
		r = Array.new
		while d < self.end_date
			if long
				r << [d.strftime("%B"), d.month]
			else
				r << { i: d.month, name: (long ? d.strftime("%B") : d.strftime("%^b")) }
			end
			d = d + 1.month
		end
		r
	end

	# return the latest season registered
	def self.latest
		last_date = Season.maximum('start_date')
		return last_date ? Season.real.where(start_date: last_date).first : nil
	end

	# parse data from raw input given by submittal from "new" or "edit"
	def rebuild(f_data)
		self.start_date = f_data[:start_date] if f_data[:start_date]
		self.end_date   = f_data[:end_date] if f_data[:end_date]
	end
end
