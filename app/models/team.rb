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
class Team < ApplicationRecord
	before_destroy :unlink
	belongs_to :club
	belongs_to :category
	belongs_to :division
	belongs_to :season
	belongs_to :sport
	has_and_belongs_to_many :players
	has_and_belongs_to_many :coaches
	has_one :homecourt
	has_one :rules, through: :category
	has_many :slots, dependent: :destroy
	has_many :events, dependent: :destroy
	has_many :team_targets, dependent: :destroy
	has_many :targets, through: :team_targets
	accepts_nested_attributes_for :coaches
	accepts_nested_attributes_for :players
	accepts_nested_attributes_for :events
	accepts_nested_attributes_for :targets
	accepts_nested_attributes_for :team_targets
	default_scope { order(category_id: :asc) }
	scope :real, -> { where("id>0") }
	scope :for_season, -> (s_id) { where("season_id = ?", s_id) }

	# get attendance data for a team in the season
	# returns partial & serialised numbers for attendance: trainings [%]
	def attendance
		t_players = self.players.count
		return nil if t_players.zero?	# NO PLAYERS IN TEAM --> NO ATTENDANCE DATA
		
		d_morrow = Date.today + 1	# tomorrow
		d_last7  = d_morrow - 8	# date limit for last 7 days
		d_last30 = d_morrow - 31	# date limit for last 30 days
		l_week   = {tot: 0, att: 0}
		l_month  = {tot: 0, att: 0}
		l_season = {tot: 0, att: 0}
		sessions = {name: I18n.t("player.many"), avg: 0, data: {}}
		s_avg    = 0
		t_events = self.events.past.trainings.includes(:events_players)
		t_att    = EventAttendance.for_team(self.id)
		t_events.each do |event|
			if event.train?
				e_cnt           = t_att.for_event(event.id).count
				e_date          = event.start_date
				l_season[:tot] += t_players
				l_season[:att] += e_cnt
				sessions[:avg] += e_cnt
				if e_date.between?(d_last30, d_morrow)	# event in last month
					l_month[:tot]  += t_players
					l_month[:att]  += e_cnt
					if (e_date > d_last7)	# event occurs in last 7 days
						l_week[:att] += e_cnt
						l_week[:tot] += t_players
					end
				end
				sessions[:data][e_date] = e_cnt # add to sessions
			end
		end
		sessions[:week]  = l_week[:tot]>0 ? (100*l_week[:att]/l_week[:tot]).to_i : nil
		sessions[:month] = l_month[:tot]>0 ? (100*l_month[:att]/l_month[:tot]).to_i : nil
		sessions[:avg]   = l_season[:tot]>0 ? (100*l_season[:att]/l_season[:tot]).to_i : nil
		{ sessions: sessions }
	end

	# collective target filtering methods
	def collective_def(month=0)
		search_targets(month, 2, 2)
	end

	def collective_off(month=0)
		search_targets(month, 2, 1)
	end

	# Get a list of players that are valid to play in this team
	def eligible_players
		s_year = self.season.start_year
		aux = Player.active.joins(:person).where("birthday > ? AND birthday < ?", self.category.oldest(s_year), self.category.youngest(s_year)).order(:birthday)
		if aux
			case self.category.sex
				when "female"
					aux = aux.female
				when "male"
					aux = aux.male
				else
					(aux + self.players).uniq
			end
		end
		aux
	end

	# general Team target filtering methods
	def general_def(month=0)
		search_targets(month, 0, 2)
	end

	def general_off(month=0)
		search_targets(month, 0, 1)
	end

	def has_coach(c_id)
		self.coaches.find_index { |c| c[:id]==c_id }
	end

	def has_player(p_id)
		self.players.find_index { |p| p[:id]==p_id }
	end

	# Individual skill target filtering methods
	def individual_def(month=0)
		search_targets(month, 1, 2)
	end

	def individual_off(month=0)
		search_targets(month, 1, 1)
	end

	# check if drill (or associations) has changed
	def modified?
		res = self.changed? || @modified
		unless res
			res = self.players.any?(&:saved_changes?)
			unless res
				res = self.team_targets.any?(&:saved_changes?)
				unless res
					res = self.coaches.any?(&:saved_changes?)
				end
			end
		end
		res
	end

	# return next free training_slot
	# after the last existing one in the calendar
	def next_slot(last=nil)
		d   = last ? last.start_time.to_date : Date.today	# last planned slot date
		res = nil
		self.slots.each { |slot|
			s   = slot.next_date(d)
			res = res ? (s < res.next_date(d) ? slot : res) : slot
		}
		return res
	end

	# Get a list of players that are not members but are authorised to play in this team
	def optional_players
		res = []
		self.eligible_players.each {|player|
			res << player unless player.teams.include?(self)
		}
		res.empty? ? nil : res
	end

	# rebuild Teamm from raw hash returned by a form
	def rebuild(f_data)
		self.category_id  = f_data[:category_id].to_i if f_data[:category_id]
		self.club_id      = f_data[:club_id].presence if f_data[:club_id].present?
		self.division_id  = f_data[:division_id].to_i if f_data[:division_id]
		self.homecourt_id = f_data[:homecourt_id].to_i if f_data[:homecourt_id]
		self.name         = f_data[:name] if f_data[:name]
		self.season_id    = f_data[:season_id].to_i if f_data[:season_id]
		self.sport_id     = f_data[:sport_id].to_i if f_data[:sport_id]
		check_targets(f_data[:team_targets_attributes]) if f_data[:team_targets_attributes]
		check_players(f_data[:player_ids]) if f_data[:player_ids]
		check_coaches(f_data[:coach_ids]) if f_data[:coach_ids]
	end

	# return team name in string format
	def to_s
		if self.name.present?
			self.id==0 ? I18n.t("scope.none") : self.name.to_s
		else
			self.category.to_s
		end
	end

	# Return upcoming events for the Team
	def upcoming_events
		self.events.non_training.short_term
	end

	# return a hash with {won:, lost:} games
	def win_loss
		res     = {won: 0, lost: 0}
		matches = self.events.matches
		matches.each do |m|
			score = m.total_score # our team first
			if score[:ours][:points] > score[:opps][:points]
				res[:won]  += 1
			elsif score[:opps][:points] > score[:ours][:points]
				res[:lost] += 1
			end
		end
		res
	end

	# Wrappper to handle creation of a new Team from params
	# received from Teams form, discarding the optional arguments
	def self.build(f_data)
		t_data = f_data.permit(
			:category_id,
			:club_id,
			:division_id,
			:homecourt_id,
			:name,
			:season_id,
			:sport_id,
			coach_ids: []
		)
		Team.new(t_data)
	end

	# Search teams for a club matching season
	def self.search(club_id:, season_id: nil)
		if (season_id = season_id.presence.to_i) > 0
			Team.where(club_id:, season_id:).order(:category_id)
		else
			Team.where(club_id:).order(:category_id)
		end
	end

	private
		# ensure we get the right targets
		def check_targets(t_array)
			a_targets = Array.new	# array to include all targets
			t_array.each do |t| # first pass
				if t[1][:_destroy]  # we must include to remove it
					a_targets << t[1]
				else
					a_targets << t[1] unless a_targets.detect { |a| a[:target_attributes][:concept] == t[1][:target_attributes][:concept] }
				end
			end
			a_targets.each do |t| # second pass - manage associations
				if t[:_destroy] == "1"	# remove team_target
					TeamTarget.find(t[:id].to_i).delete
					@modified = true
				else	# ensure creation of team_targets
					tt = TeamTarget.fetch(t)
					tt.save unless tt.persisted?
					@modified = true unless self.team_targets.include?(tt)
					self.team_targets ? self.team_targets << tt : self.team_targets |= tt
				end
			end
		end

		# ensure we get the right players
		def check_players(p_array)
			a_targets = Array.new	# array to include all targets
			p_array.each do |t|	# first pass
				a_targets << Player.find(t.to_i) unless t.to_i==0
			end
		
			a_targets.each do |t|	# second pass - manage associations
				unless self.has_player(t.id)
					self.players << t 
					@modified = true
				end
			end
			
			self.players.each do |p|	# cleanup roster
				unless a_targets.include?(p)
					self.players.delete(p)
					@modified = true
				end
			end
		end

		# ensure we get the right players
		def check_coaches(c_array)
			
			a_targets = Array.new	# array to include all targets
			c_array.each do |t|	# first pass
				a_targets << Coach.find(t.to_i) unless t.to_i==0
			end
			
			a_targets.each do |t|	# second pass - manage associations
				unless self.has_coach(t.id)
					self.coaches << t
					@modified = true
				end
			end
			
			self.coaches.each do |c|	# cleanup coaches
				unless a_targets.include?(c)
					self.coaches.delete(c)
					@modified = true
				end
			end
		end

		# search team_targets based on target attributes
		def search_targets(month=0, aspect=nil, focus=nil)
			#puts "Plan.search(team: " + ", month: " + month.to_s + ", aspect: " + aspect.to_s + ", focus: " + focus.to_s + ")"
			tgt = self.team_targets.monthly(month)
			res = Array.new
			tgt.each do |p|
				puts p.to_s
				if aspect && focus
					res.push p if ((p.target.aspect_before_type_cast == aspect) && (p.target.focus_before_type_cast == focus))
				elsif aspect
					res.push p if (p.target.aspect_before_type_cast == aspect)
				elsif focus
					res.push p if (p.target.focus_before_type_cast == focus)
				else
					res.push p
				end
			end
			res
		end

		# unlink dependents properly, if deleting team
		def unlink
			self.players.delete_all
			self.coaches.delete_all
			UserAction.prune("/teams/#{self.id}")
		end
end
