# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
class Event < ApplicationRecord
  localized_as "calendar.event"

  after_initialize :set_changed_flag
  before_destroy :unlink

  #-------------------------------------
  # Data accessors
  #-------------------------------------
  attr_accessor :event_changed
  enum :kind, %i[rest train match]
  self.inheritance_column = "not_sti"

  #-------------------------------------
  # Object relationships
  #-------------------------------------
  belongs_to :club
  belongs_to :team, optional: true
  belongs_to :location

  has_many :event_targets, dependent: :destroy
  has_many :targets, through: :event_targets
  has_many :tasks, -> { order(order: :asc).includes(:drill).with_rich_text_remarks }, dependent: :destroy
  has_many :stats, dependent: :destroy
  has_many :attendances, dependent: :destroy

  # no HABTM players in the final 2.0 interface
  has_and_belongs_to_many :players	# DEPRECATED

  accepts_nested_attributes_for :targets, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :event_targets, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :tasks, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :stats, reject_if: :all_blank, allow_destroy: true

  #-------------------------------------
  # Data validations
  #-------------------------------------
  validate :team_in_same_club

  #-------------------------------------
  # ActiveRecord scopes
  #-------------------------------------
  pg_search_scope :search_by_name,
                  against: :name,
                  ignoring: :accents,
                  using: { tsearch: { prefix: true } }

  scope :chronological, -> { order(:start_time) }
  scope :between, ->(from, to) { where(start_time: from..to) }
  scope :of_kind, ->(kind) { where(kind:) }
  scope :for_club, ->(club) { where(club:).chronological }
  scope :for_team, ->(team) { where(team:).chronological }
  scope :for_season, ->(season) { between(season.start_date, season.end_date) }
  scope :club_events, -> { where(team_id: nil) }
  scope :team_events, -> { where.not(team_id: nil) }
  scope :past, -> { where("start_time < ?", Time.current) }
  scope :upcoming, -> { where("start_time > ?", Time.current) }

  scope :last7, -> { between(Date.today - 7, Date.today + 1) }
  scope :last30, -> { between(Date.today - 30, Date.today + 1) }
  scope :this_week, -> { between(Time.current.at_beginning_of_week, Time.current.at_end_of_week) }
  scope :this_month, -> { between(Time.current.at_beginning_of_month, Time.current.at_end_of_month) }
  scope :this_season, -> { where("end_time < ?", Time.current) }
  scope :short_term, -> { between(Time.current - 1.day.to_i, Time.current + 1.week.to_i) }
  scope :for_season, ->(season) { between(season.start_date, season.end_date) }
  scope :normal,    -> { where("kind > 0") }
  scope :matches,   -> { where(kind: :match) }
  scope :trainings, -> { where(kind: :train) }
  scope :holidays,  -> { where(kind: :rest) }
  scope :non_training, -> { where("kind=2 or (kind=0 and team_id=0)") }

  #-------------------------------------
  # Event model Generic API
  #-------------------------------------

  # show this event?
  def display?
    return true unless rest?
    return true if team.present?

    true
  end

  def date_string
    cad = self.start_time.year.to_s
    cad = cad + "/" + two_dig(self.start_date.month)
    cad = cad + "/" + two_dig(self.start_date.day)
  end

  def duration
    return 0 unless start_time && end_time

    ((end_time - start_time) / 60).to_i
  end

  def duration=(minutes)
    return if start_time.blank?

    self.end_time = start_time + minutes.to_i.minutes
  end

  def hour
    self.start_time.hour
  end

  def hour=(newhour)
    self.start_time = self.start_time.change({ hour: newhour })
  end

  def min
    self.start_time.min
  end

  def min=(newmin)
    self.start_time = self.start_time.change({ min: newmin })
  end

  # check if event (or associations) has changed
  def modified?
    res = self.changed? || @event_changed
    unless res
      res = self.stats.any?(&:saved_changes?)
      unless res
        res = self.event_targets.any?(&:saved_changes?)
        unless res
          res = self.tasks.any?(&:saved_changes?)
        end
      end
    end
    res
  end

  def start_date
    self.start_time.to_date
  end

  def time_string(t_end = true)
    timeslot_string(t_begin: self.start_time, t_end: ((self.train? and t_end) ? self.end_time : nil))
  end

  # rebuild Event using raw hash from a form submittal
  def rebuild(f_data, s_data = nil)
    self.start_time = f_data[:start_date] if f_data[:start_date]
    self.hour = f_data[:hour].to_i if f_data[:hour]
    self.min = f_data[:min].to_i if f_data[:min]
    self.duration = f_data[:duration].to_i if f_data[:duration]
    self.name = f_data[:name] if f_data[:name]
    self.location_id = f_data[:location_id].to_i if f_data[:location_id]
    self.home = f_data[:home] if f_data[:home]
    check_stats(s_data) if s_data # manage stats if provided
    check_targets(f_data[:event_targets_attributes]) if f_data[:event_targets_attributes]
    check_tasks(f_data[:tasks_attributes]) if f_data[:tasks_attributes]
  end

  # prepare default values for an event
  def prepare_defaults(start_date: nil)
    date = start_date.present? ? Date.parse(start_date) : Date.current

    case kind.to_sym
    when :rest
      prepare_rest(date)

    when :train
      prepare_training(date)

    when :match
      prepare_match(date)
    end
  end

  # DEPRECATED: legacy Player compatibility.
  def has_player(p_id)
    self.players.find_index { |p| p[:id] == p_id }
  end

  #-------------------------------------
  # Event presentation helpers
  #-------------------------------------

  # return name of assocatied symbol
  def symbol
    case self.kind.to_sym
    when :train
      concept = "training"
    when :match
      namespace = self&.team&.sport&.name || "sport"
      concept = "match"
    when :rest
      concept   = "rest"
    else
      concept = "team"
      namespace = "common"
    end
    namespace ||= "sport"
    { concept:, options: { namespace: } }
  end

  # return event title depending on kind & data
  def title(show: nil, copy: nil, print: nil)
    cad = show ? "" : (self.id ? (copy ? "#{I18n.t("action.copy")} " : "#{I18n.t("action.edit")} ") : "#{I18n.t("action.create")}")
    e_string = I18n.t("#{self.kind}.single")
    case self.kind.to_sym
    when :rest
      cad += e_string
      cad += ": #{self.name}" if print
    when :train
      cad = show ? self.team.to_s : "#{cad}#{e_string}"
    when :match
      if print
        m_data = self.to_hash
        return "#{m_data[:home_t]} - #{m_data[:away_t]}"
      else
        cad = self.team.to_s
      end
    else
      cad += "(¿?)"
    end
    cad
  end

  # hash view of event data
  # {home_t:, home_p, away_t:, away_p}
  def to_hash(mode: 1)
    if self.match?
      m_score = self.total_score
      ours = m_score[:ours]
      opps = m_score[:opps]
      if self.home?
        res = { home_t: ours[:team], home_p: ours[:points], away_t: opps[:team], away_p: opps[:points] }
      else
        res = { home_t: opps[:team], home_p: opps[:points], away_t: ours[:team], away_p: ours[:points] }
      end
    else
      res = { home_t: self.name }
    end
    res
  end

  # string view of object
  def to_s(style: nil)
    case self.kind.to_sym
    when :train
      res = I18n.t("train.single")
    when :match
      if style == "short"
        res = I18n.t("match.single")
      else
        m_row = self.to_hash
        home = m_row[:home_t] + " [" + m_row[:home_p].to_s + "]"
        away = "[" + m_row[:away_p].to_s + "] " + m_row[:away_t]
        res = home + "-" + away
      end
    when :rest
      res = self.name
    else
      res = ""
    end
    res = res + " (" + self.date_string + ")" if style == "notice"
    res
  end

  #-------------------------------------
  # Training events
  #-------------------------------------

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

  # return strings fro associated targets
  def print_targets(kind: nil)
    cad = ""
    self.targets.each do |target|
      cad += "\n\t" unless cad == ""
      cad += target.concept
    end
    cad
  end

  # return a collection of Drills associated with this event
  def drill_list
    res = Array.new
    self.tasks.each { |tsk| res.push(tsk.drill) }
    res.uniq
  end

  # string with duration and minutes indication (')
  def s_dur
    self.duration.to_s + "\'"
  end

  def work_duration
    res = 0
    self.tasks.each { |tsk| res = res + tsk.duration }
    res.to_s + "\'"
  end

  #-------------------------------------
  # Competition events
  #-------------------------------------

  # Scores accessor modes:
  # places  our team first
  def total_score
    score = self.team.sport.specific.match_score(self.id)
    our_s = { team: self.team.to_s, points: score[:tot][:ours] }
    opp_s = { team: self.name, points: score[:tot][:opps] }
    { ours: our_s, opps: opp_s }
  end

  #-------------------------------------
  # Class methods
  #-------------------------------------

  # Find a slot matching slot form data
  def self.next(s_data)
    unless s_data.empty?
      t = Time.new(2021, 8, 30, s_data[:hour].to_i + 1, s_data[:min].to_i)
      Slot.where(wday: s_data[:wday].to_i, start: t, team_id: s_data[:team_id].to_i).or(Slot.where(wday: s_data[:wday].to_i, start: t, location_id: s_data[:location_id].to_i)).first
    else
      nil
    end
  end

  # prepare a new Event using data provided
  def self.prepare(data)
    club = Club.find_by(id: data[:club_id])
    return nil unless club

    team = Team.find_by(id: data[:team_id])
    return nil if team && team.club != club

    event = new(club:, team:, kind: data[:kind])
    event.prepare_defaults(start_date: data[:start_date])

    event
  end

  # Search for a list of Events
  # s_data is an array with either club_id+season_id+kind+name or team_id+kind+name
  def self.search(params = {})
    events =
      if params[:team_id].present?
        team = Team.find_by(id: params[:team_id])
        return none unless team
        for_team(team)
      elsif params[:club_id].present?
        club = Club.find_by(id: params[:club_id])
        return none unless club
        for_club(club)
      else
        upcoming
      end

    if params[:season_id].present?
      season = Season.find_by(id: params[:season_id])
      events = events.for_season(season) if season
    end

    events = events.of_kind(params[:kind]) if params[:kind].present?
    events = events.search_by_name(params[:name]) if params[:name].present?

    events.chronological
  end

  private

  # Default values for a rest Event
  def prepare_rest(date)
    self.name = I18n.t("event_kinds.values.rest")
    self.start_time = date
    self.duration = 1440
    self.location_id = 0
  end

  def prepare_training(date)
    return unless team

    self.name = I18n.t("event_kinds.values.training")

    slot = team.next_slot(team.events.trainings.last)

    if slot
      training_date =  slot.next_date || date

      self.start_time =
        (training_date + slot.hour.hours + slot.min.minutes).to_datetime

      self.duration = slot.duration
      self.location_id = slot.location_id
    else
      self.start_time = (date + 16.hours).to_datetime
      self.duration = 60
      self.location_id = 0
    end
  end

  def prepare_match(date)
    return unless team

    last = team.events.matches.last || Event.new(start_time: Time.current)

    self.start_time =
      if last
        last.start_time + 7.days
      else
        date + last.hour.hours + ((last.min / 15).round * 5).minutes
      end

    self.duration = 120
    self.location_id = team.homecourt_id
  end

  # check stats added to event
  def check_stats(s_data)
    e_stats = self.stats
    s_data.each do |s_param|
      s_arg = s_param[0].split("_")
      stat = Stat.fetch(event_id: self.id, period: 0, player_id: s_arg[0].to_i, concept: s_arg[1], stats: e_stats).first
      if stat # just update the value
        stat[:value] = s_param[1].to_i
      else # create a new stat
        e_stats << Stat.new(event_id: self.id, period: 0, player_id: s_arg[0].to_i, concept: s_arg[1], value: s_param[1].to_i)
      end
    end
  end

  # checks targets_attributes parameter received and manage adding/removing
  # from the target collection - remove duplicates from list
  def check_targets(t_array)
    a_targets = Target.passed(t_array)
    t_pri = { def: 1, off: 1 }
    a_targets.each do |t| # second pass - manage associations
      if t[:_destroy] == "1" # remove event_target
        self.targets.delete(t[:target_attributes][:id].to_i)
      elsif t[:target_attributes]
        dt = EventTarget.fetch(t)
        if dt.target&.offense?
          priority = t_pri[:off]
          t_pri[:off] += 1
        elsif dt.target&.defense?
          priority = t_pri[:def]
          t_pri[:def] += 1
        else
          priority = 1
        end
        dt.update(priority:)
        self.event_targets ? self.event_targets << dt : self.event_targets |= dt
      end
    end
  end

  # checks tasks_attributes parameter received and manage adding/removing
  # from the task collection - ALLOWING DUPLICATES.
  def check_tasks(t_array)
    order = 1
    t_array.each { |t| # manage associations
      tsk = self.tasks.find_by_id(t[1][:id].to_i)
      if t[1][:_destroy] == "1" # delete task
        tsk.delete
      else
        tsk.rebuild(t[1])
        tsk.order = order
        @event_changed = tsk.save if tsk.changed?
        order += 1
      end
    }
  end

  def set_changed_flag
    @event_changed = false
  end

  # cleanup dependent teams, reassigning to 'dummy' category
  def unlink
    case self.kind.to_sym
    when :rest
      unless self.team_id # clean off copies
        season = Season.search_date(self.start_date)
        if season # we have a season for this event
          club.teams.for_season(season.id).each { |team| # delete event from all teams
            e_copy = Event.holidays.where(team_id: team.id, name: self.name, start_time: self.start_time).first
            e_copy.delete if e_copy # delete linked event
          }
        end
      end
    when :train, :match
      self.players.delete_all
    end
    UserAction.prune("/events/#{self.id}")
  end

  def team_in_same_club
    return if team.blank?
    return if team.club_id == club_id

    errors.add(:team, :invalid)
  end
end
