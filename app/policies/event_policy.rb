# MudDrill - The open source Rails platform to manage amateur sports drills.
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
# app/policies/event_policy.rb
class EventPolicy < ApplicationPolicy
	def initialize(actor, record: nil, club: nil, team: nil, person: nil, token: nil)
		if record.is_a?(Event)
			super(actor, record:, club: record.club)
			@target_team = record.team
		else
			super(actor, club:)
			if team.is_a?(Team)
				@target_team = team
				@target_club = team.club if team.id != 0
			end
		end
		@target_person = person if person.is_a?(Person)
	end

	def index?
		allowed?(same_club?(target_club))
	end

	def show?
		return false unless @record&.persisted?
		return true if admin? || manages_club?(target_club)
		if @target_team
			@target_team.has_assignment_for?(actor_person) ||
			manages_coaches?(target_club)
		else	# club-wide event
			same_club?(target_club)
		end
	end
	alias load_chart? show?

	# ---------------------------------------------------------------------------
	# CRUD & derivates
	# ---------------------------------------------------------------------------
	def create?
		allowed?(
			manages_club?(target_club) ||
			manages_coaches?(target_club) ||
			manages_team?(@target_team)
		)
	end
	alias new? create?

	def edit?
		manages_event?
			@record.start_date > Date.today - 1.week
	end

	alias add_task? edit?
	alias edit_task? edit?
	alias update? edit?
	alias destroy? edit?

	def attendance?
		manages_event? &&
			@record.start_date > Date.today - 1.month
	end

	def copy?
		@record && create?
	end

	def show_task?
		return false unless @record&.persisted?
		return has_team_assignment?(@target_team) if @target_team
		has_club_assignment?(target_club)
	end
	alias edit_task? add_task?

	def athlete_stats?
		return false unless @target_person&.is_athlete? || @record&.persisted?
		return false if @record&.kind_holiday? # not keeping stats for holidays ;)

		manages_event? || same_person?(@target_person)
	end
	alias edit_athlete_stats? athlete_stats?

	# wrapper to determine whether the user can modify the event.
	# proabbly needs some refinement in fuuture depending on @event type
	def manages_event?
		return false unless @record&.persisted?
		manages_club?(target_club) ||
			@target_team && manages_team?(@target_team)
	end

	def export?
		return true if @target_team && coaches_team?(@target_team)
		manages_club?(@target_club)
	end
end
