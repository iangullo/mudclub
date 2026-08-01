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
class AssignmentPolicy < ApplicationPolicy
	def initialize(actor, record: nil, kind: nil, member: nil, team: nil, club: nil)
		super(actor, record:)
		@target_kind   = @record&.kind || kind.presence
		@target_member = @record&.membership || member.presence
		@target_team   = @record&.team || team.presence
		@target_club   = @target_team&.club || club.presence
	end

	def index?
		allowed?(
			same_club?(@target_club) &&
			can_view_kind?(@target_kind)
		)
	end

	def show?
		allowed?(
			same_person?(@record) || (
				same_club?(@record) &&
				can_view_kind?(@target_kind)
			)
		)
	end

	def new?
		allowed?(
			same_club?(@target_club) &&
			can_manage_kind?(@target_kind)
		)
	end

	alias create? new?

	def update?
		allowed?(
			same_club?(@record) &&
			can_manage_kind?(@target_kind)
		)
	end

	alias edit?      update?
	alias terminate? update?

	private
		def can_view_kind?(kind)
			return false unless kind

			case kind.to_sym
			when :athlete, :captain
				coach? ||
				manages_athletes?(@target_club) ||
				manages_team?(@target_team)

			when :head_coach,	:assistant_coach, :team_manager,
				:team_delegate, :home_delegate
				coach? ||
				manages_coaches?(@target_club) ||
				manages_team?(@target_team)

			when :coaching_coordinator
				coach? ||
				manages_coaches?(@target_club)

			when :photographer, :community_manager, :webmaster, :club_manager
				manages_club?(@target_club)

			when :president, :vice_president, :secretary, :treasurer
				manages_club?(@target_club)

			else
				false
			end
		end

		def can_manage_kind?(kind)
			return false unless kind

			case kind.to_sym
			when :athlete, :captain
				coaches_team?(@target_team) ||
				manages_athletes?(@target_club) ||
				manages_club?(@target_club)

			when :team_manager
				manages_club?(@target_club)

			when :head_coach, :coaching_coordinator
				manages_coaches?(@target_club)

			when :assistant_coach, :team_delegate, :home_delegate
				manages_club?(@target_club) ||
				manages_team?(@target_team)

			when :photographer, :community_manager, :webmaster
				manages_club?(@target_club)

			when :club_manager, :president, :vice_president, :secretary, :treasurer
				manages_board?(@target_club)

			else
				false
			end
		end
end
