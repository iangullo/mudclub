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
class Team < ApplicationRecord
	belongs_to :category
	belongs_to :division
	belongs_to :season
	has_and_belongs_to_many :players
	has_and_belongs_to_many :coaches
	has_many :slots
	has_many :events
	has_many :team_targets
	has_many :targets, through: :team_targets
	accepts_nested_attributes_for :coaches
	accepts_nested_attributes_for :players
	accepts_nested_attributes_for :events
	accepts_nested_attributes_for :targets
	accepts_nested_attributes_for :team_targets
	default_scope { order(category_id: :asc) }
	scope :real, -> { where("id>0") }
	scope :for_season, -> (s_id) { where("season_id = ?", s_id) }
	enum rules: {
		fiba: 0,
		q4: 1,
		q6: 2
	}

	def to_s
		if self.name and self.name.length > 0
			self.name.to_s
		else
			self.category.to_s
		end
	end

	# Get a list of players that are valid to play in this team
	def eligible_players
		s_year = self.season.start_year
		aux = Player.active.joins(:person).where("birthday > ? AND birthday < ?", self.category.oldest(s_year), self.category.youngest(s_year)).order(:birthday)
		if aux
			case self.category.sex
				when "Fem."
					aux = aux.female
				when "Masc."
					aux = aux.male
				else
					aux
			end
		end
		aux
	end

	#Search field matching season
	def self.search(search)
		if search
			s_id = search.to_i
			s_id > 0 ? Team.for_season(s_id).order(:category_id) : Team.real
		else
			Team.real
		end
	end

	def has_coach(c_id)
		self.coaches.find_index { |c| c[:id]==c_id }
	end

	def has_player(p_id)
		self.players.find_index { |p| p[:id]==p_id }
	end

	def general_def(month=0)
		search_targets(month, 0, 2)
	end

	def general_off(month=0)
		search_targets(month, 0, 1)
	end

	def individual_def(month=0)
		search_targets(month, 1, 2)
	end

	def individual_off(month=0)
		search_targets(month, 1, 1)
	end

	def collective_def(month=0)
		search_targets(month, 2, 2)
	end

	def collective_off(month=0)
		search_targets(month, 2, 1)
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

	# get attendance data for a team in the season
	# returns partial & serialised numbers for attendance: trainings [%]
	def attendance
		t_players  = self.players.count
		if t_players > 0
			l_week = {tot: 0, att: 0}
			l_month = {tot: 0, att: 0}
			l_season = {tot: 0, att: 0}
			sessions = {name: I18n.t("player.many"), avg: 0, data: {}}
			d_last7  = Date.today - 7
			d_last30 = Date.today - 30
			self.events.normal.this_season.each { |event|
				if event.train?
					e_att = event.players.count	# how many came?
					l_week[:tot] = l_week[:tot] + t_players if event.start_date > d_last7
					l_month[:tot] = l_month[:tot] + t_players if event.start_date > d_last30
					l_season[:tot] = l_season[:tot] + t_players
					sessions[:data][event.start_date] = e_att.to_i # add to sessions
					l_week[:att] = l_week[:att] + e_att if event.start_date > d_last7
					l_month[:att] = l_month[:att] + e_att if event.start_date > d_last30
					l_season[:att] = l_season[:att] + e_att
					sessions[:avg] = sessions[:avg] + e_att
				end
			}
			sessions[:week] = l_week[:tot]>0 ? (100*l_week[:att]/l_week[:tot]).to_i : nil
			sessions[:month] = l_month[:tot]>0 ? (100*l_month[:att]/l_month[:tot]).to_i : nil
			sessions[:avg] = l_season[:tot]>0 ? (100*l_season[:att]/l_season[:tot]).to_i : nil
			{sessions: sessions}
		else
			nil	# NO PLAYERS/SESSIONS IN THE TEAM --> NO ATTENDANCE DATA TO SHOW
		end
	end

	# return time rules that apply to this team
	def periods
		self.rules ? self.rules : self.category.def_rules
	end

	# rebuild Teamm from raw hash returned by a form
	def rebuild(p_data)
		self.name         = p_data[:name] if p_data[:name]
		self.season_id    = p_data[:season_id].to_i if p_data[:season_id]
		self.category_id  = p_data[:category_id].to_i if p_data[:category_id]
		self.division_id  = p_data[:division_id].to_i if p_data[:division_id]
		self.homecourt_id = p_data[:homecourt_id].to_i if p_data[:homecourt_id]
		self.rules        = Team.rules[p_data[:rules]].to_i if p_data[:rules]
		check_targets(p_data[:team_targets_attributes]) if p_data[:team_targets_attributes]
		check_players(p_data[:player_ids]) if p_data[:player_ids]
		check_coaches(p_data[:coach_ids]) if p_data[:coach_ids]
	end

	# return a hash with {won:, lost:} games
	def win_loss
		res     = {won: 0, lost: 0}
		matches = self.events.matches.this_season
		matches.each {|m|
			score = m.score(mode: 0) # our team first
			if score[:home][:points] > score[:away][:points]
				res[:won] = res[:won] + 1
			elsif score[:away][:points] > score[:home][:points]
				res[:lost] = res[:lost] + 1
			end
		}
		res
	end

private
	# search team_targets based on target attributes
	def search_targets(month=0, aspect=nil, focus=nil)
		#puts "Plan.search(team: " + ", month: " + month.to_s + ", aspect: " + aspect.to_s + ", focus: " + focus.to_s + ")"
		tgt = self.team_targets.monthly(month)
		res = Array.new
		tgt.each { |p|
			puts p.to_s
			if aspect and focus
				res.push p if ((p.target.aspect_before_type_cast == aspect) and (p.target.focus_before_type_cast == focus))
			elsif aspect
				res.push p if (p.target.aspect_before_type_cast == aspect)
			elsif focus
				res.push p if (p.target.focus_before_type_cast == focus)
			else
				res.push p
			end
		}
		res
	end

	# ensure we get the right targets
	def check_targets(t_array)
		a_targets = Array.new	# array to include all targets
		t_array.each { |t| # first pass
			a_targets << t[1] # unless a_targets.detect { |a| a[:target_attributes][:concept] == t[1][:target_attributes][:concept] }
		}
		a_targets.each { |t| # second pass - manage associations
			if t[:_destroy] == "1"	# remove team_target
				TeamTarget.find(t[:id].to_i).delete
			else	# ensure creation of team_targets
				tt = TeamTarget.fetch(t)
				tt.save unless tt.persisted?
				self.team_targets ? self.team_targets << tt : self.team_targets |= tt
			end
		}
	end

	# ensure we get the right players
	def check_players(p_array)
		# first pass
		a_targets = Array.new	# array to include all targets
		p_array.each { |t| a_targets << Player.find(t.to_i) unless t.to_i==0 }
		# second pass - manage associations
		a_targets.each { |t| self.players << t unless self.has_player(t.id)	}
		# cleanup roster
		self.players.each { |p| self.players.delete(p) unless a_targets.include?(p) }
	end

	# ensure we get the right players
	def check_coaches(c_array)
		# first pass
		a_targets = Array.new	# array to include all targets
		c_array.each { |t| a_targets << Coach.find(t.to_i) unless t.to_i==0 }
		# second pass - manage associations
		a_targets.each { |t| self.coaches << t unless self.has_coach(t.id) }
		# cleanup roster
		self.coaches.each { |c| self.coaches.delete(c) unless a_targets.include?(c) }
	end
end
