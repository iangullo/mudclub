class Slot < ApplicationRecord
	belongs_to :season
	belongs_to :team
	belongs_to :location
	scope :for_season, -> (s_id) { where("season_id = ?", s_id) }
	scope :for_team, -> (t_id) { where("team_id = ?", t_id) }
	scope :for_location, -> (l_id) { where("location_id = ?", l_id) }
	self.inheritance_column = "not_sti"

	def to_s
		self.weekday + " (" + self.timeslot_string + ")"
	end

	def court
		Location.find(self.location_id).name
	end

	def gmaps_url
		self.location.gmaps_url
	end

	def weekday(long=false)
		long ? Date::DAYNAMES[self.wday] : Date::ABBR_DAYNAMES[self.wday]
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
				 Slot.where(season_id: s_data[:season_id].to_i, location_id: s_data[:location_id].to_i)
			 else
				 Slot.where(season_id: s_data[:season_id].to_i)
			 end
		elsif s_data[:team_id]
			if s_data[:location_id]
				Slot.where(team_id: s_data[:team_id].to_i, location_id: s_data[:location_id].to_i)
			else
				Slot.where(team_id: s_data[:team_id].to_i)
			end
		else
			Slot.all
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

	# CALCULATE HOW MANY cols we need to reserve for this day
	# i.e. overlapping teams in same location/time
	def self.timecols(sea_id, loc_id, wday)
		res    = 1
		s_time = Time.new(2021,9,1,16,0)
		e_time = Time.new(2021,9,1,22,30)
		t_time = s_time
		w_slots = self.for_season(sea_id).for_location(loc_id).where(wday: wday)
		while t_time < e_time do	# check the full day
			s_count = 0
			w_slots.each { |slot|
				s_count = s_count+1 if slot.at_work?(wday,t_time)
			}
			res     = s_count if s_count > res
			t_time  = t_time + 15.minutes
		end
		res
	end

	private
	# starting / ending hours as string
	def timeslot_string
		e = self.ending
		two_dig(self.hour) + ":" + two_dig(self.min) + "-" + two_dig(e.hour) + ":" + two_dig(e.min)
	end

	def two_dig(num)
		num.to_s.rjust(2,'0')
	end
end
