class Event < ApplicationRecord
  belongs_to :team
  belongs_to :location
  has_many :event_targets
  has_many :targets, through: :event_targets
  has_many :tasks
  accepts_nested_attributes_for :targets, reject_if: :all_blank, allow_destroy: true
	accepts_nested_attributes_for :event_targets, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :tasks, reject_if: :all_blank, allow_destroy: true
  scope :trainings, -> { where("kind = 1") }
  scope :matches, -> { where("kind = 2") }
  self.inheritance_column = "not_sti"

  enum kind: {
    holiday: 0,
    train: 1,
    match: 2
  }

  def start_date
    self.start_time.to_date
  end

  def hour
		self.start_time.hour
	end

	def min
		self.start_time.min
	end

	def hour=(newhour)
		self.start_time = self.start_time.change({ hour: newhour })
	end

	def min=(newmin)
		self.start_time = self.start_time.change({ min: newmin })
	end

	def duration
		(self.end_time - self.start_time).minutes
	end

  def duration=(newduration)
		self.end_time = self.start_time + newduration.minutes
	end

  def date_string
    cad = self.start_time.year.to_s
    cad = cad + "/" + two_dig(self.month)
    cad = cad + "/" + two_dig(self.day)
  end

  def time_string
    two_dig(self.hour) + ":" + two_dig(self.min)
  end

  # Search for a list of Events
	# s_data is an array with either season_id+kind+name or team_id+kind+name
	def self.search(s_data)
    if s_data[:team_id]  # filter for the team received
      if s_data[:kind]    # and kind
        if s_data[:name]  # and name
          res = Event.where("unaccent(name) ILIKE unaccent(?) and kind = (?) and team_id= (?)","%#{s_data[:name]}%",s_data[:kind],s_data[:team_id]).order(:start_time)
        else  # only team & kind
          res = Event.where("kind = (?) and team_id= (?)",s_data[:kind],s_data[:team_id]).order(:start_time)
        end
      elsif s_data[:name] # team & name only
        res = Event.where("unaccent(name) ILIKE unaccent(?) and team_id= (?)","%#{s_data[:name]}%",s_data[:team_id]).order(:start_time)
      else  # only team_id
        res = Event.where(team_id: s_data[:team_id].to_i).order(:start_time)
      end
		else
			Event.none
		end
	end

	# Find a slot matching slot form data
	def self.next(s_data)
		unless s_data.empty?
			t = Time.new(2021,8,30,s_data[:hour].to_i+1,s_data[:min].to_i)
			Slot.where(wday: s_data[:wday].to_i, start: t, team_id: s_data[:team_id].to_i).or(Slot.where(wday: s_data[:wday].to_i, start: t, location_id: s_data[:location_id].to_i)).first
		else
			nil
		end
	end

  private
  # starting / ending hours as string

  def two_dig(num)
    num.to_s.rjust(2,'0')
  end
end
