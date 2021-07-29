class TrainingSession < ApplicationRecord
  belongs_to :team
  belongs_to :training_slot
	belongs_to :location
	has_many :exercises
	accepts_nested_attributes_for :exercises, reject_if: :all_blank, allow_destroy: true
	scope :for_team, -> (t_id) { where("team_id = ?", t_id) }
	scope :at_location, -> (l_id) { where("location_id = ?", l_id) }
	self.inheritance_column = "not_sti"

	def hour
		self.training_slot.hour
	end
	
	def min
		self.training_slot.min
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
	
	# IMPORTANT: use this instead of "date=" after object initialization
	def set_date(newdate)
		case newdate
			when Date
				self.date = newdate
			when String, DateTime
				self.date = newdate.to_date
			else
				self.date = DateTime.now.to_date
		end
		check_training_slot
	end
	
	def self.search(search)
		if search
			TrainingSession.where(team_id: Team.where(["id = ? or name LIKE ?",search,search])).order(:date)
		else
			TrainingSession.all.order(:date)
		end
	end
	
	def time_string
		two_dig(self.hour)+ ":" + two_dig(self.min)
	end
	
	def next_session
		new_slot = self.training_slot.next_slot
		new_date = self.date.next_occurring(Date::DAYNAMES[new_slot.wday].downcase.to_sym)
		TrainingSession.new(team_id: self.team_id, training_slot_id: new_slot.id, date: new_date)
	end
	
	private
	def check_training_slot
		ts = TrainingSlot.for_team(self.team_id).find_by(wday: self.date.wday)
		self.training_slot_id = ts ? ts.id : 0
	end

	def two_dig(num)
		num.to_s.rjust(2,'0')
	end
end
