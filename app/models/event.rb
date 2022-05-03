class Event < ApplicationRecord
  belongs_to :team
  belongs_to :location
  has_many :event_targets
  has_many :targets, through: :event_targets
  has_many :tasks
  has_many :stats
  accepts_nested_attributes_for :targets, reject_if: :all_blank, allow_destroy: true
	accepts_nested_attributes_for :event_targets, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :tasks, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :stats, reject_if: :all_blank, allow_destroy: true
  scope :upcoming, -> { where("start_time > ?", Time.now) }
  scope :for_season, -> (season) { where("start_time > ? and end_time < ?", season.start_date, season.end_date) }
  scope :normal, -> { where("kind > 0") }
  scope :holidays, -> { where("kind = 0") }
  scope :trainings, -> { where("kind = 1") }
  scope :matches, -> { where("kind = 2") }
  self.inheritance_column = "not_sti"

  enum kind: {
    holiday: 0,
    train: 1,
    match: 2
  }

  def to_s(long=nil)
    case self.kind.to_sym
    when :train
      res = self.name
      res = res + " (" + self.date_string+ ")" if long
    when :match
      res = long ? self.team.name + " " : ""
      res = res + (self.home? ? " vs " : " @ ") + self.name
      res = res + " (" + self.date_string + ")" if long
    when :holiday
      res=self.name
    else
      res = ""
    end
    res
  end

  # show this event?
  def display?
    if self.holiday? and self.team_id > 0 # we have a team holiday?
      e = Event.where(team_id: 0, start_time: self.start_time)  # is it general?
      return false if e.first # don't display it!
    end
    return true
  end

  def form_label
    cad = self.id ? I18n.t(:m_edit) : I18n.t(:m_create)
    case self.kind.to_sym  # depending on event kind
    when :holiday
      cad = cad + I18n.t(:l_rest)
    when :train
      cad = cad + I18n.t(:l_train)
    when :match
      cad = cad + I18n.t(:l_match)
    else
      cad = cad + "(¿?)"
    end
  end

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
		((self.end_time - self.start_time)/60).to_i
	end

  def duration=(newduration)
		self.end_time = self.start_time + newduration.minutes
	end

  def work_duration
    res = 0
    self.tasks.each { |tsk| res = res + tsk.duration }
    res.to_s + "\'"
  end

  def date_string
    cad = self.start_time.year.to_s
    cad = cad + "/" + two_dig(self.start_date.month)
    cad = cad + "/" + two_dig(self.start_date.day)
  end

  def time_string
    two_dig(self.hour) + ":" + two_dig(self.min)
  end

  # return list of defensive targets
  def def_targets
    res = Array.new
    self.event_targets.each { |tev|
      res << tev if tev.target.defense?
    }
    res
  end

  # return list of offensive targets
  def off_targets
    res = Array.new
    self.event_targets.each { |tev|
      res << tev if tev.target.offense?
    }
    res
  end

  # Search for a list of Events
	# s_data is an array with either season_id+kind+name or team_id+kind+name
	def self.search(s_data)
    s_id = s_data[:season_id] ? s_data[:season_id].to_i : nil
    t_id = s_data[:team_id] ? s_data[:team_id].to_i : nil
    kind = s_data[:kind] ? s_data[:kind].to_sym : nil
    if s_id
      res = Event.for_season(Season.find(s_id)).order(:start_time)
    elsif t_id  # filter for the team received
      if kind   # and kind
        if s_data[:name]  # and name
          res = Event.where("unaccent(name) ILIKE unaccent(?) and kind = (?) and team_id= (?)","%#{s_data[:name]}%",kind,t_id).order(:start_time)
        else  # only team & kind
          res = Event.where("kind = (?) and team_id= (?)",kind,t_id).order(:start_time)
        end
      elsif s_data[:name] # team & name only
        res = Event.where("unaccent(name) ILIKE unaccent(?) and team_id= (?)","%#{s_data[:name]}%",t_id).order(:start_time)
      else  # only team_id
        res = Event.where(team_id: t_id).order(:start_time)
      end
		else
			res = Event.upcoming.order(:start_time)
		end
	end

  def self.prepare(s_data)
    team = Team.find(s_data[:team_id] ? s_data[:team_id].to_i : 0)
    res  = Event.new(team_id: team.id, kind: s_data[:kind].to_sym)
    case res.kind.to_sym  # depending on event kind
    when :holiday
      res.name        = I18n.t(:l_rest)
      res.start_time  = Date.current
      res.duration    = 1440
      res.location_id = 0
    when :train
      last            = team.events.trainings.last
      slot            = team.next_slot(last)
      return nil unless slot
      res.name        = I18n.t(:l_train)
      res.start_time  = (slot.next_date + slot.hour.hours + slot.min.minutes).to_datetime
      res.duration    = slot.duration
      res.location_id = slot.location_id
    when :match
      last            = team.events.matches.last
      starting        = last ? (last.start_time + 7.days) : (Date.today.next_occurring(Date::DAYNAMES[0].downcase.to_sym) + 10.hours)
      res.name        = I18n.t(:d_match)
      res.start_time  = starting
      res.duration    = 120
      res.location_id = team.homecourt_id
    else
      res = nil
    end
    return res
  end

  # return a collection of Drills associated with this event
  def drill_list
    res = Array.new
    self.tasks.each { |tsk| res.push(tsk.drill) }
    res.uniq
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
