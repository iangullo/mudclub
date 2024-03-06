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
# Class to manage club seasons
class Season < ApplicationRecord
	before_destroy :unlink
	has_many :slots, dependent: :destroy
	has_many :teams, dependent: :destroy
	scope :real, -> { where("id>0") }
	self.inheritance_column = "not_sti"

	# elgible locations to train / play
	def eligible_locations
		Location.real - self.locations
	end

	# returns theyear where a season ends
	def end_year
		self.end_date.year.to_i
	end

	# Return club-wide events for this season
	def events
		Event.for_season(self).non_training
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

	# return season name - taking start & finish years
	def name(safe: nil)
		if self.id == 0	# fake season for all events/teams
			cad = I18n.t("scope.all")
		else
			cad = self.start_year.to_s
			if self.end_year > self.start_year
				sep  = safe ? "_" : "/"
				cad += "#{sep}#{(self.end_year % 100)}"
			end
		end
		cad
	end

	# parse data from raw input given by submittal from "new" or "edit"
	def rebuild(f_data)
		self.start_date = f_data[:start_date] if f_data[:start_date]
		self.end_date   = f_data[:end_date] if f_data[:end_date]
	end

	def start_year
		self.start_date.year.to_i
	end

	# ensure clean deleting of a Season - SHOULD NEVER HAPPEN!!
	def unlink
		self.slots.delete_all
		self.teams.delete_all
		self.locations.delete_all
		UserAction.prune("/seasons/#{self.id}")
	end

	# return the latest season registered
	def self.latest
		# check past seasons
		if (past_start = Season.where("start_date <= ?", Date.today).maximum('start_date'))
			if (p_season = Season.where(start_date: past_start).first)
				if p_season.end_date < Date.today
					next_start = Season.where("start_date > ?", Date.today).minimum('start_date')
					p_season   = Season.where(start_date: next_start).first
				end
			end
		end
		p_season
	end

	# options list for search-select boxes
	def self.list
		res = []
		Season.real.order(start_date: :desc).each do |season|
			res << [season.name, season.id]
		end
		return res
	end

	#Search field matching
	def self.search(search)
		res   = (Season.find_by_id(search) || Season.search_date(search)) if search.present?
		res ||= Season.latest
		return (res || Season.real.last)
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
end
