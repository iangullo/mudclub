class TrainingSlot < ApplicationRecord
	belongs_to :season
	belongs_to :team
	has_one :location
	scope :for_team, -> (t_id) { where("team_id = ?", t_id) }
	scope :for_location, -> (l_id) { where("location_id = ?", l_id) }

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

	def at_work?(wday, t_hour)
		if self.wday == wday
			if t_hour.hour.between?(self.hour, self.ending.hour)
				if t_hour.hour == self.hour
					return ((t_hour.min >= self.min) and ((self.ending.hour > self.hour) or (t_hour.min < self.ending.min)))
				elsif t_hour.hour == self.ending.hour
					return (t_hour.min < self.ending.min)
				else
					return true
				end
			end
		end
	end

	#gives us the next TrainingSlot for this sequence
	def next_slot
		ts = TrainingSlot.for_team(self.team_id)
		i  = (self.wday == 5) ? 1 : self.wday + 1
		ns = ts.find_by(wday: i)
		until ns do	# loop to find next
			i = (i == 5) ? 1 : i + 1
			ns = ts.find_by(wday: i)
		end
		ns
	end

	#gives us the next TrainingSlot for this sequence
	def next_date
		Date.today.next_occurring(Date::DAYNAMES[self.wday].downcase.to_sym)
	end

	#Search for specific court
	def self.search(search)
		if search
			l_id = search.to_i
			l_id > 0 ? TrainingSlot.for_location(l_id).order(:wday) : TrainingSlot.all
		else
			TrainingSlot.all
		end
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
