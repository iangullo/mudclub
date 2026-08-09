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

		@target_kind   = @record&.kind || kind
		@target_member = @record&.membership || member
		@target_team   = @record&.team || team
		@target_club   = @target_team&.club || @record&.club || club
	end

	def index?
		allowed?(
			same_club?(@target_club) &&
			can_view_kind?(@target_kind)
		)
	end

	def show?
		allowed?(
			same_person?(@record) ||
			shared_assignment_context?(@actor) ||
			(
				same_club?(@target_club) &&
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
			same_club?(@target_club) &&
			can_manage_kind?(@target_kind)
		)
	end

	alias edit? update?
	alias update_status? update?
	alias edit_status? update?
	alias terminate? update?

	def history?
		allowed?(
			same_club?(@target_club) &&
			can_view_history?(@target_kind)
		)
	end

	private

		def can_view_kind?(kind)
			return false unless kind

			if Catalog::AssignmentKinds.team_level?(kind)
				can_view_team_assignment?(kind)
			else
				can_view_club_assignment?(kind)
			end
		end

		def can_manage_kind?(kind)
			return false unless kind

			if Catalog::AssignmentKinds.team_level?(kind)
				can_manage_team_assignment?(kind)
			else
				can_manage_club_assignment?(kind)
			end
		end

		def can_view_team_assignment?(kind)
			case Catalog::AssignmentKinds.membership_kind(kind)
			when :athlete, :volunteer
				coach? ||
				manages_athletes?(@target_club) ||
				manages_team?(@target_team)

			when :coach
				coach? ||
				manages_coaches?(@target_club) ||
				manages_team?(@target_team)

			else
				false
			end
		end

		def can_manage_team_assignment?(kind)
			case Catalog::AssignmentKinds.membership_kind(kind)
			when :athlete, :volunteer
				coaches_team?(@target_team) ||
				manages_athletes?(@target_club) ||
				manages_club?(@target_club)

			when :coach
				manages_coaches?(@target_club) ||
				manages_club?(@target_club)

			else
				false
			end
		end

		def can_view_club_assignment?(kind)
			case Catalog::AssignmentKinds.scope_of(kind)
			when :club
				manages_club?(@target_club)

			when :board
				manages_board?(@target_club)

			else
				false
			end
		end

		def can_manage_club_assignment?(kind)
			case Catalog::AssignmentKinds.scope_of(kind)
			when :club
				manages_club?(@target_club)

			when :board
				manages_board?(@target_club)

			else
				false
			end
		end

		def can_view_history?(kind)
			can_view_kind?(kind)
		end

		# Collaboration permission
		def shared_assignment_context?(actor)
			return false unless actor.person

			if @target_team
				@target_team.has_assignment_for?(actor.person)
			else
				@target_club&.has_assignment_for?(actor.person)
			end
		end
end
