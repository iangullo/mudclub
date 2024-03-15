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
#
class Event < ApplicationRecord
	after_initialize :set_changed_flag
	before_destroy :unlink
	attr_accessor :event_changed
	belongs_to :team
	belongs_to :location
	has_many :event_targets, dependent: :destroy
	has_many :targets, through: :event_targets
	has_many :tasks, -> { order(order: :asc).includes(:drill).with_rich_text_remarks }, dependent: :destroy
	has_many :stats, dependent: :destroy
	has_and_belongs_to_many :players
	accepts_nested_attributes_for :targets, reject_if: :all_blank, allow_destroy: true
	accepts_nested_attributes_for :event_targets, reject_if: :all_blank, allow_destroy: true
	accepts_nested_attributes_for :tasks, reject_if: :all_blank, allow_destroy: true
	accepts_nested_attributes_for :stats, reject_if: :all_blank, allow_destroy: true
	pg_search_scope :search_by_name,
		against: :name,
		ignoring: :accents,
		using: { tsearch: {prefix: true} }
	scope :last7, -> { where("start_time > ? and end_time < ?", Date.today-7, Date.today+1).order(:start_time) }
	scope :last30, -> { where("start_time > ? and end_time < ?", Date.today-30, Date.today+1).order(:start_time) }
	scope :this_week, -> { where("start_time > ? and end_time < ?", Time.now.at_beginning_of_week, Time.now.at_end_of_week).order(:start_time) }
	scope :this_month, -> { where("start_time > ? and end_time < ?", Time.now.at_beginning_of_month, Time.now.at_end_of_month).order(:start_time) }
	scope :this_season, -> { where("end_time < ?", Time.now).order(:start_time) }
	scope :short_term, -> { where("start_time > ? and end_time < ?", Time.now - 1.day.to_i, Time.now + 1.week.to_i).order(:start_time) }
	scope :past, -> { where("start_time < ?", Time.now).order(:start_time) }
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

	# string view of object
	def to_s(style: nil)
		case self.kind.to_sym
		when :train
			res = I18n.t("train.single")
		when :match
			m_row = self.to_hash
			home  = m_row[:home_t] + " [" + m_row[:home_p].to_s + "]"
			away  = "[" + m_row[:away_p].to_s + "] " + m_row[:away_t]
			res   = home + "-" + away
		when :rest
			res=self.name
		else
			res = ""
		end
		res = res + " (" + self.date_string + ")" if style=="notice"
		res
	end

	# hash view of event data
	# {home_t:, home_p, away_t:, away_p}
	def to_hash(mode: 1)
		if self.match?
			m_score = self.total_score
			ours    = m_score[:ours]
			opps    = m_score[:opps]
			if self.home?
				res = {home_t: ours[:team] , home_p: ours[:points], away_t: opps[:team], away_p: opps[:points]}
			else
				res = {home_t: opps[:team] , home_p: opps[:points], away_t: ours[:team], away_p: ours[:points]}
			end
		else
			res = {home_t: self.name}
		end
		res
	end

	# string with duration and minutes indication (')
	def s_dur
		self.duration.to_s + "\'"
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

	# return event title depending on kind & data
	def title(show: nil, copy: nil)
		cad = show ? "" : (self.id ? (copy ? "#{I18n.t('action.copy')} " : "#{I18n.t('action.edit')} ") : "#{I18n.t('action.create')}")
		case self.kind.to_sym
		when :rest
			cad += I18n.t("rest.single")
		when :train
			cad = show ? self.team.to_s : "#{cad}#{I18n.t('train.single')}"
		when :match
			cad += I18n.t("match.single")
		else
			cad += "(¿?)"
		end
		cad
	end

	# wrappers to read/update event values
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

	def time_string(t_end=true)
		timeslot_string(t_begin: self.start_time, t_end: ((self.train? and t_end) ? self.end_time : nil))
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
	# places  our team first
	def total_score
		score = self.team.sport.specific.match_score(self.id)
		our_s = {team: self.team.to_s, points: score[:tot][:ours]}
		opp_s = {team: self.name, points: score[:tot][:opps]}
		{ours: our_s, opps: opp_s}
	end

	# check if player is in this event
	def has_player(p_id)
		self.players.find_index { |p| p[:id]==p_id }
	end

	# rebuild Event using raw hash from a form submittal
	def rebuild(f_data, s_data=nil)
		self.start_time = f_data[:start_date] if f_data[:start_date]
		self.hour       = f_data[:hour].to_i if f_data[:hour]
		self.min        = f_data[:min].to_i if f_data[:min]
		self.duration   = f_data[:duration].to_i if f_data[:duration]
		self.name       = f_data[:name] if f_data[:name]
		self.p_for      = f_data[:p_for].to_i if f_data[:p_for]
		self.p_opp      = f_data[:p_opp].to_i if f_data[:p_opp]
		self.location_id= f_data[:location_id].to_i if f_data[:location_id]
		self.home       = f_data[:home] if f_data[:home]
		check_stats(s_data) if s_data # manage stats if provided
		check_targets(f_data[:event_targets_attributes]) if f_data[:event_targets_attributes]
		check_tasks(f_data[:tasks_attributes]) if f_data[:tasks_attributes]
	end

	# check if drill (or associations) has changed
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

	# Search for a list of Events
	# s_data is an array with either club_id+season_id+kind+name or team_id+kind+name
	def self.search(s_data)
		if (c_id = s_data[:club_id]&.to_i) && (s_id = s_data[:season_id]&.to_i)
			club = Club.find_by_id(c_id)	# non-training club events
			res  = Event.where(team_id: club.teams.where(season_id: s_id).pluck(:id)).order(start_time: :asc)
		elsif (t_id = s_data[:team_id]&.to_i)  # filter for the team received
			s_name = s_data[:name].presence
			if kind = s_data[:kind]&.to_sym	# and kind
				if s_name  # and name
					res = Event.where(kind: kind, team_id: t_id).search_by_name(s_name).order(:start_time)
				else  # only team & kind
					res = Event.where(kind: kind, team_id: t_id).order(:start_time)
				end
			elsif s_name # team & name only
				res = Event.where(team_id: t_id).search_by_name(s_name).order(:start_time)
			else  # only team_id
				res = Event.where(team_id: t_id).order(:start_time)
			end
		else
			res = Event.upcoming.order(:start_time)
		end
	end

	# prepare a new Event using data provided
	def self.prepare(s_data)
		team   = Team.find(s_data[:team_id] ? s_data[:team_id].to_i : 0)
		res    = Event.new(team_id: team.id, kind: s_data[:kind].to_sym)
		s_date = s_data[:start_date] ? Date.parse(s_data[:start_date]) : nil
		c_date = s_date ? s_date : Date.current
		case res.kind.to_sym  # depending on event kind
		when :rest
			res.name        = I18n.t("rest.single")
			res.start_time  = c_date
			res.duration    = 1440
			res.location_id = 0
		when :train
			res.name = I18n.t("train.single")
			last     = team.events.trainings.last
			slot     = team.next_slot(last)
			if slot
				s_date          = s_date ? s_date : slot.next_date
				res.start_time  = (s_date + slot.hour.hours + slot.min.minutes).to_datetime
				res.duration    = slot.duration
				res.location_id = slot.location_id
			else
				res.start_time  = (c_date + 16.hours + 0.minutes).to_datetime
				res.duration    = 60
				res.location_id = 0
			end
		when :match
			last = team.events.matches.last
			last = Event.new(start_time: Time.now) unless last
			if s_date
				starting = s_date + last.hour.hours + ((last.min/15).round*5).minutes
			else
				starting = last ? (last.start_time + 7.days) : (Date.today.next_occurring(Date::DAYNAMES[0].downcase.to_sym) + 10.hours)
			end
			res.name        = nil
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

	private
		# check stats added to event
		def check_stats(s_data)
			e_stats = self.stats
			s_data.each do |s_param|
				s_arg = s_param[0].split("_")
				stat = Stat.fetch(event_id: self.id, period: 0, player_id: s_arg[0].to_i, concept: s_arg[1], stats: e_stats).first
				if stat # just update the value
					stat[:value] = s_param[1].to_i
				else  # create a new stat
					e_stats << Stat.new(event_id: self.id, period: 0, player_id: s_arg[0].to_i, concept: s_arg[1], value: s_param[1].to_i)
				end
			end
		end

		# checks targets_attributes parameter received and manage adding/removing
		# from the target collection - remove duplicates from list
		def check_targets(t_array)
			a_targets = Target.passed(t_array)
			t_pri = {def: 1, off: 1}
			a_targets.each do |t| # second pass - manage associations
				if t[:_destroy] == "1"	# remove event_target
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
				if t[1][:_destroy] == "1"	# delete task
					tsk.delete
				else
					tsk.rebuild(t[1])
					tsk.order      = order
					@event_changed = tsk.save if tsk.changed?
					order         += 1
				end
			}
		end

		# cleanup dependent teams, reassigning to 'dummy' category
		def unlink
			case self.kind.to_sym
			when :rest
				if self.team_id==0  # clean off copies
					season = Season.search_date(self.start_date)
					if season # we have a season for this event
						season.teams.real.each { |team| # delete event from all teams
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

		def set_changed_flag
			@event_changed = false
		end
end
