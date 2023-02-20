# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
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
			m_score = self.score(mode:)
			if self.home?
				home_t = self.team.name
				away_t = self.name
			else
				home_t = self.name
				away_t = self.team.name
			end
			home_p = m_score[:home][:points]
			away_p = m_score[:away][:points]
			res = {home_t:, home_p:, away_p:, away_t:}
		else
			res = {home_t: self.name}
		end
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
	#   0:  our team first
	#   1:  home team first
	#   2:  away team first
	def score(mode: 1)
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

	# check if player is in this event
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

	# rebuild Event using raw hash from a form submittal
	def rebuild(e_data, s_data=nil)
		self.start_time = e_data[:start_date] if e_data[:start_date]
		self.hour       = e_data[:hour].to_i if e_data[:hour]
		self.min        = e_data[:min].to_i if e_data[:min]
		self.duration   = e_data[:duration].to_i if e_data[:duration]
		self.name       = e_data[:name] if e_data[:name]
		self.p_for      = e_data[:p_for].to_i if e_data[:p_for]
		self.p_opp      = e_data[:p_opp].to_i if e_data[:p_opp]
		self.location_id= e_data[:location_id].to_i if e_data[:location_id]
		self.home       = e_data[:home] if e_data[:home]
		check_stats(s_data) if s_data # manage stats if provided
		check_targets(e_data[:event_targets_attributes]) if e_data[:event_targets_attributes]
		check_tasks(e_data[:tasks_attributes]) if e_data[:tasks_attributes]
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

	# prepare a new Event using data provided
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

	private
		# check stats added to event
		def check_stats(s_data)
			e_stats = self.stats
			s_params.each {|s_param|
				s_arg = s_param[0].split("_")
				stat = Stat.fetch(event_id: self.id, player_id: s_arg[0].to_i, concept: s_arg[1], stats: e_stats)
				if stat # just update the value
					stat[:value] = s_param[1].to_i
				else  # create a new stat
					e_stats << Stat.new(event_id: self.id, player_id: s_arg[0].to_i, concept: s_arg[1], value: s_param[1].to_i)
				end
			}
		end

		# checks targets_attributes parameter received and manage adding/removing
		# from the target collection - remove duplicates from list
		def check_targets(t_array)
			a_targets = Array.new	# array to include only non-duplicates
			t_array.each { |t| # first pass
				if t[1][:_destroy]  # we must include to remove it
					a_targets << t[1]
				else
					a_targets << t[1] unless a_targets.detect { |a| a[:target_attributes][:concept] == t[1][:target_attributes][:concept] }
				end
			}
			a_targets.each { |t| # second pass - manage associations
				if t[:_destroy] == "1"	# remove drill_target
					self.targets.delete(t[:target_attributes][:id].to_i)
				elsif t[:target_attributes]
					dt = EventTarget.fetch(t)
					self.event_targets ? self.event_targets << dt : self.event_targets |= dt
				end
			}
		end

		# checks tasks_attributes parameter received and manage adding/removing
		# from the task collection - ALLOWING DUPLICATES.
		def check_tasks(t_array)
			t_array.each { |t| # manage associations
				if t[1][:_destroy] == "1"	# delete task
					Task.find(t[1][:id].to_i).delete
				else
					tsk = Task.fetch(t[1])
					tsk.save
				end
			}
		end
end
