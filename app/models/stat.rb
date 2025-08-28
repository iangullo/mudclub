# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
class Stat < ApplicationRecord
	belongs_to :event
	belongs_to :player  # id==0 => team stat; id==-1 => rival stat
	scope :real, -> { where("id>0") }
	scope :for_event, ->(e_id) { where(event_id: e_id) }
	scope :for_team, -> { where(player_id: 0) }
	scope :for_rival, -> { where(player_id: -1) }
	scope :for_players, -> { where("player_id>0") }
	scope :for_player, ->(p_id) { where(player_id: p_id) }
	scope :for_concept, ->(cval) { where(concept: cval) }
	self.inheritance_column = "not_sti"

	# wrappers to access value & concept fields
	def concept
		self[:concept]
	end

	def value
		self[:value]
	end

	# fetch stats based on event, period, player & concept
	# if none found, a new one is created. a collection is returned
	def self.fetch(event_id: nil, period: nil, player_id: nil, concept: nil, stats: Stat.real, create: true)
		stats = Stat.by_event(event_id, stats) if event_id
		stats = Stat.by_player(player_id, stats) if player_id
		stats = Stat.by_period(period, stats) if period
		stats = Stat.by_concept(concept, stats) if concept
		stats << Stat.new(event_id:, period:, player_id:, concept:, value: 0) if create && stats.empty?
		stats
	end

	# filter stats by event
	def self.by_event(event_id, stats = Stat.real)
		stats.select { |stat| stat.event_id==event_id }
	end

	# filter stats by period
	def self.by_period(period, stats = Stat.real)
		stats.select { |stat| stat.period == period }
	end

	# filter stats by player
	def self.by_player(player_id, stats = Stat.for_players)
		stats.select { |stat| stat.player_id == player_id }
	end

	# filter stats by player
	def self.by_concept(concept, stats = Stat.real)
		stats.select { |stat| stat.concept == concept }
	end

	# filter stats by quarter
	def self.by_q(q, stats = Stat.for_players)
		stats.select { |stat| stat[:concept]=="q#{q}" }
	end
end
