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
class EventAttendance < ApplicationRecord
	self.table_name = "events_players"
	belongs_to :event
	belongs_to :player
	scope :for_event, ->(event_id) { where(event_id:) }
	scope :for_player, ->(player_id) { where(player_id:) }
	scope :for_team, ->(team_id) { joins(:event).where("team_id = #{team_id}") }
	scope :matches, -> { joins(:event).where(events: { kind: Event.kinds[:match] }) }
	scope :trainings, -> { joins(:event).where(events: { kind: Event.kinds[:train] }) }
	scope :last7, -> { joins(:event).where("start_time > ? and end_time < ?", Date.today-7, Date.today+1).order(:start_time) }
	scope :last30, -> { joins(:event).where("start_time > ? and end_time < ?", Date.today-30, Date.today+1).order(:start_time) }
	self.inheritance_column = "not_sti"

	# Count total attendance for an event. 'e_att' can be either an event_id and
	# query the database for the count, or a collection of EventAttendance objs.
	# to sum.
	def self.count(e_att)
		case e_att
		when Integer
			EventAttendance.where(event_id: e_att).count
		else
			e_att.count
		end
	end

	# fetch (or create) an EventAttendance object for event_id and player_id
	def self.fetch(event_id, player_id, create: false)
		res   = EventAttendance.find_by(event_id:, player_id:)
		res ||= EventAttendance.new(event_id:, player_id:) if create
		res
	end

	# prepare an EventAttendance object to record  attendance of event_id and player_id
	def self.prepare(event_id, player_id)
		res = self.fetch(event_id, player_id, create: true)
		res
	end
end
