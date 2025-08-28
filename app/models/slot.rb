# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
class Slot < ApplicationRecord
	before_destroy :unlink
	belongs_to :location
	belongs_to :season
	belongs_to :team
	scope :real, -> { where("id>0") }
	scope :for_season, ->(s_id) { where("season_id = ?", s_id) }
	scope :for_team, ->(t_id) { where("team_id = ?", t_id) }
	scope :for_location, ->(l_id) { where("location_id = ?", l_id) }
	self.inheritance_column = "not_sti"

	# return if timetable row should be kept busy with this slot
	def at_work?(wday, t_hour)
		if self.wday == wday
			if t_hour.hour.between?(self.hour, self.ending.hour)
				if t_hour.hour == self.hour
					((t_hour.min >= self.start.min) and ((self.ending.hour > self.hour) or (t_hour.min < self.ending.min)))
				elsif t_hour.hour == self.ending.hour
					(t_hour.min < self.ending.min)
				else
					true
				end
			end
		end
	end

	def court
		Location.find(self.location_id).name
	end

	def ending
		self.start + self.duration.minutes
	end

	def gmaps_url
		self.location.gmaps_url
	end

	def hour
		self.start.hour
	end

	def hour=(newhour)
		self.start = self.start.change({ hour: newhour })
	end

	def min
		self.start.min
	end

	def min=(newmin)
		self.start = self.start.change({ min: newmin })
	end

	# gives us the next Slot for this sequence
	def next_date(from_date = Date.today)
		from_date = from_date - 1.day
		from_date.next_occurring(Date::DAYNAMES[self.wday].downcase.to_sym)
	end

	# build new @slot from raw input given by submittal from "new" or "edit"
	# always returns a @slot
	def rebuild(f_data)
		self.wday        = f_data[:wday] if f_data[:wday].present?
		self.hour        = f_data[:hour] if f_data[:hour].present?
		self.min         = f_data[:min] if f_data[:min].present?
		self.duration    = f_data[:duration] if f_data[:duration].present?
		self.location_id = f_data[:location_id].to_i if f_data[:location_id].present?
		self.team_id     = f_data[:team_id].to_i if f_data[:team_id].present?
		self.season_id   = self.team.season_id.to_i
	end

	# CALCULATE HOW MANY cols we need to reserve for this slot
	# i.e. avoid overlapping teams in same location/time
	def timecols(daycols, w_slots: nil)
		o_count = 0	# overlaps
		t_time  = self.start
		w_slots = Slot.real.for_season(self.season_id)
			.for_location(self.location_id)
			.where(wday: self.wday).order(:start) unless w_slots
		unless w_slots.empty? # no other slots?
			while t_time < self.ending do	# check for overlaps
				overlaps = 0
				w_slots.each { |slot|	# check each potential slot
					unless slot.id==self.id
						overlaps = overlaps + 1 if slot.at_work?(wday, t_time)
					end
				}
				o_count = overlaps if overlaps > o_count
				t_time  = t_time + 15.minutes # scan more?
			end
		end
		daycols - o_count
	end

	# number of timetable  rows required
	# each row represents 15 minutes
	def timerows(wday, t_hour)
		if self.wday == wday
			if t_hour.hour == self.hour && t_hour.min == self.min
				srows = self.duration/15.to_i
				srows
			end
		end
	end

	def to_s(with_day = true)
		t_string = self.timeslot_string(t_begin: self.start, t_end: self.ending)
		return t_string unless with_day
		self.weekday + " (#{t_string})"
	end

	# unlink slot to avoid issues
	def unlink
		UserAction.prune("/slots/#{self.id}")
	end

	def weekday(long = false)
		long ? I18n.t("calendar.daynames")[self.wday] : I18n.t("calendar.daynames_a")[self.wday]
	end

	# filter slots that start at or end after start_time
	def self.at_time(start_time, slots = Slot.real)
		slots.select { |slot| slot.at_work?(slot.wday, start_time) }
	end

	# Find a slot matching slot form data
	def self.fetch(s_data)
		unless s_data.empty?
			t = Time.new(2021, 8, 30, s_data[:hour].to_i+1, s_data[:min].to_i)
			Slot.where(wday: s_data[:wday].to_i, start: t, team_id: s_data[:team_id].to_i).or(Slot.where(season_id: s_data[:season_id]&.to_i, wday: s_data[:wday].to_i, start: t, location_id: s_data[:location_id].to_i)).first
		else
			nil
		end
	end

	# Search for a list of SLots
	# s_data is an array with either season_id+location_id or team_id
	def self.search(s_data)
		if s_data[:season_id].present?
			if s_data[:location_id].present?
				Slot.real.where(season_id: s_data[:season_id].to_i, location_id: s_data[:location_id].to_i).order(:start)
			else
				Slot.real.where(season_id: s_data[:season_id].to_i).order(:start)
			end
		elsif s_data[:team_id].present?
			if s_data[:location_id].present?
				Slot.real.where(team_id: s_data[:team_id].to_i, location_id: s_data[:location_id].to_i).order(:start)
			else
				Slot.real.where(team_id: s_data[:team_id].to_i).order(:start)
			end
		else
			Slot.real.order(:start)
		end
	end

	# filter slots by weekday
	def self.by_wday(wday, slots = Slot.real)
		slots.select { |slot| slot.wday==wday }
	end
end
