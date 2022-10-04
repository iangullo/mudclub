class Slot < ApplicationRecord
	belongs_to :season
	belongs_to :team
	belongs_to :location
	scope :real, -> { where("id>0") }
	scope :for_season, -> (s_id) { where("season_id = ?", s_id) }
	scope :for_team, -> (t_id) { where("team_id = ?", t_id) }
	scope :for_location, -> (l_id) { where("location_id = ?", l_id) }
	self.inheritance_column = "not_sti"

	def to_s
		self.weekday + " (" + self.timeslot_string(t_begin: self.start, t_end: self.ending) + ")"
	end

	def court
		Location.find(self.location_id).name
	end

	def gmaps_url
		self.location.gmaps_url
	end

	def weekday(long=false)
		long ? I18n.t("calendar.daynames")[self.wday] : I18n.t("calendar.daynames_a")[self.wday]
	end

	def hour
		self.start.hour
	end

	def min
		self.start.min
	end

	def hour=(newhour)
		self.start = self.start.change({ hour: newhour })
	end

	def min=(newmin)
		self.start = self.start.change({ min: newmin })
	end

	def ending
		self.start + self.duration.minutes
	end

	# return if timetable row should be kept busy with this slot
	def at_work?(wday, t_hour)
		if self.wday == wday
			if t_hour.hour.between?(self.hour, self.ending.hour)
				if t_hour.hour == self.hour
					return ((t_hour.min >= self.start.min) and ((self.ending.hour > self.hour) or (t_hour.min < self.ending.min)))
				elsif t_hour.hour == self.ending.hour
					return (t_hour.min < self.ending.min)
				else
					return true
				end
			end
		end
	end

	# number of timetable  rows required
	# each row represents 15 minutes
	def timerows(wday, t_hour)
		if self.wday == wday
			if (t_hour.hour == self.hour && t_hour.min == self.min)
				srows = self.duration/15.to_i
				return srows
			end
		end
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
						overlaps = overlaps + 1 if slot.at_work?(wday,t_time)
					end
				}
				o_count = overlaps if overlaps > o_count
				t_time  = t_time + 15.minutes # scan more?
			end
		end
		res = daycols - o_count
	end

	#gives us the next Slot for this sequence
	def next_date(from_date=Date.today)
		from_date = from_date - 1.day
		from_date.next_occurring(Date::DAYNAMES[self.wday].downcase.to_sym)
	end

	# Ensure we remove dependencies of location before deleting.
  def scrub
		self.seasons.clear
  end

	# Search for a list of SLots
	# s_data is an array with either season_id+location_id or team_id
	def self.search(s_data)
		if s_data[:season_id]
			 if s_data[:location_id]
				 Slot.real.where(season_id: s_data[:season_id].to_i, location_id: s_data[:location_id].to_i).order(:start)
			 else
				 Slot.real.where(season_id: s_data[:season_id].to_i).order(:start)
			 end
		elsif s_data[:team_id]
			if s_data[:location_id]
				Slot.real.where(team_id: s_data[:team_id].to_i, location_id: s_data[:location_id].to_i).order(:start)
			else
				Slot.real.where(team_id: s_data[:team_id].to_i).order(:start)
			end
		else
			Slot.real.order(:start)
		end
	end

	# Find a slot matching slot form data
	def self.fetch(s_data)
		unless s_data.empty?
			t = Time.new(2021,8,30,s_data[:hour].to_i+1,s_data[:min].to_i)
			Slot.where(wday: s_data[:wday].to_i, start: t, team_id: s_data[:team_id].to_i).or(Slot.where(wday: s_data[:wday].to_i, start: t, location_id: s_data[:location_id].to_i)).first
		else
			nil
		end
	end

	# filter slots by weekday
	def self.by_wday(wday, slots=Slot.real)
		slots.select {|slot| slot.wday==wday}
	end

  # filter slots that start at or end after start_time
	def self.at_time(start_time, slots=Slot.real)
		res = slots.select {|slot| slot.at_work?(slot.wday,start_time)}
	end

	# build new @slot from raw input given by submittal from "new" or "edit"
	# always returns a @slot
	def rebuild(s_data)
    self.wday        = s_data[:wday] if s_data[:wday]
    self.hour        = s_data[:hour] if s_data[:hour]
    self.min         = s_data[:min] if s_data[:min]
    self.duration    = s_data[:duration] if s_data[:duration]
    self.location_id = s_data[:location_id] if s_data[:location_id]
    self.team_id     = s_data[:team_id] if s_data[:team_id]
    self.season_id   = self.team.season_id.to_i
	end
end
