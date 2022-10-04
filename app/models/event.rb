class Event < ApplicationRecord
  belongs_to :team
  belongs_to :location
  has_many :event_targets
  has_many :targets, through: :event_targets
  has_many :tasks
  has_many :stats
	has_and_belongs_to_many :players
  accepts_nested_attributes_for :targets, reject_if: :all_blank, allow_destroy: true
	accepts_nested_attributes_for :event_targets, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :tasks, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :stats, reject_if: :all_blank, allow_destroy: true
  scope :this_week, -> { where("start_time > ? and end_time < ?", Time.now.at_beginning_of_week, Time.now).order(:start_time) }
  scope :this_month, -> { where("start_time > ? and end_time < ?", Time.now.at_beginning_of_month, Time.now).order(:start_time) }
  scope :this_season, -> { where("end_time < ?", Time.now).order(:start_time) }
  scope :upcoming, -> { where("start_time > ?", Time.now).order(:start_time) }
  scope :for_season, -> (season) { where("start_time > ? and end_time < ?", season.start_date, season.end_date).order(:start_time) }
  scope :normal, -> { where("kind > 0").order(:start_time) }
  scope :holidays, -> { where("kind = 0").order(:start_time) }
  scope :trainings, -> { where("kind = 1").order(:start_time) }
  scope :matches, -> { where("kind = 2").order(:start_time) }
  scope :non_training, -> { where("kind=2 or (kind=0 and team_id=0)").order(:start_time) }
  self.inheritance_column = "not_sti"

  enum kind: {
    rest: 0,
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
      res = res + (self.home? ? "vs " : "@ ") + self.name
      res = res + " (" + self.date_string + ")" if long
    when :rest
      res=self.name
    else
      res = ""
    end
    res
  end

  def s_dur
    self.duration.to_s + "\'"
  end

  # Search for a list of Events
	# s_data is an array with either season_id+kind+name or team_id+kind+name
	def self.search(s_data)
    s_id = s_data[:season_id] ? s_data[:season_id].to_i : nil
    t_id = s_data[:team_id] ? s_data[:team_id].to_i : nil
    kind = s_data[:kind] ? s_data[:kind].to_sym : nil
    if s_id
      res = Event.for_season(Season.find(s_id)).non_training.order(:start_time)
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
    when :rest
      res.name        = I18n.t("rest.single")
      res.start_time  = Date.current
      res.duration    = 1440
      res.location_id = 0
    when :train
      res.name        = I18n.t("train.single")
      last            = team.events.trainings.last
      slot            = team.next_slot(last)
      if slot
        res.start_time  = (slot.next_date + slot.hour.hours + slot.min.minutes).to_datetime
        res.duration    = slot.duration
        res.location_id = slot.location_id
      else
        res.start_time  = (Date.current + 16.hours + 0.minutes).to_datetime
        res.duration    = 60
        res.location_id = 0
      end
    when :match
      last            = team.events.matches.last
      starting        = last ? (last.start_time + 7.days) : (Date.today.next_occurring(Date::DAYNAMES[0].downcase.to_sym) + 10.hours)
      res.name        = I18n.t("match.default_rival")
      res.start_time  = starting
      res.duration    = 120
      res.location_id = team.homecourt_id
    else
      res = nil
    end
    return res
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

  # return name of assocatied icon
  def pic
    case self.kind.to_sym
    when :train
      res = "training.svg"
    when :match
      res = "match.svg"
    when :rest
      res = "rest.svg"
    else
      res = "team.svg"
    end
    res
  end

  # show this event?
  def display?
    if self.rest? and self.team_id > 0 # we have a team rest?
      e = Event.where(team_id: 0, start_time: self.start_time)  # is it general?
      return false if e.first # don't display it!
    end
    return true
  end

  def title(show: nil)
    cad = show ? "" : (self.id ? I18n.t("action.edit") + " " : I18n.t("action.create") + " ")
    case self.kind.to_sym
    when :rest
      cad = cad + I18n.t("rest.single")
    when :train
      cad = show ? self.team.to_s : cad + I18n.t("train.single")
    when :match
      cad = cad + I18n.t("match.single")
    else
      cad = cad + "(¿?)"
    end
    cad
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
    self.timeslot_string(t_begin: self.start_time, t_end: (self.train? ? self.end_time : nil))
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

  # return a collection of Drills associated with this event
  def drill_list
    res = Array.new
    self.tasks.each { |tsk| res.push(tsk.drill) }
    res.uniq
  end

  # Scores accessor modes:
  #   0:  our team first
  #   1:  home team first
  #   2:  away team first
  def score(mode=1)
    p_for = self.stats.where(concept: :pts, player_id: 0).first # our team's points
    p_for = p_for ? p_for.value : 0
    p_opp = self.stats.where(concept: :pts, player_id: -1).first  # opponent points
    p_opp = p_opp ? p_opp.value : 0
    our_s = {team: self.team.to_s, points: p_for}
    opp_s = {team: self.name, points: p_opp}

    if mode==0 or (mode==1 and self.home?) or (mode==2 and self.home==false)
      {home: our_s, away: opp_s}
    else
      {home: opp_s, away: our_s}
    end
  end

  # wrapper to write points in favour of a match
  def p_for=(newval)
    p_f       = fetch_stat(0, :pts)
    p_f.value = newval
    p_f.save
  end

  # wrapper to write points against of a match
  def p_opp=(newval)
    p_o       = fetch_stat(-1, :pts)
    p_o.value = newval
    p_o.save
  end

  # fetch or create a stat for a specific concept and player of an event
  def fetch_stat(player_id, concept)
    aux = self.stats.where(player_id: player_id, concept: concept).first
    unless aux
      aux = Stat.new(event_id: self.id, player_id: player_id, concept: concept, value: 0)
    end
    aux
  end

  def has_player(p_id)
		self.players.find_index { |p| p[:id]==p_id }
	end

  # return contraints on event periods (if any)
  # nil if none
  def periods
    if self.match?
      case self.team.rules.to_sym  # ready to create period rule edition
      when :q4 then return {total: 4, max: 2, min: 3}
      when :q6 then return {total: 6, max: 3, min: 2}
      else
        return nil
      end
    else
      return nil
    end
  end
end
