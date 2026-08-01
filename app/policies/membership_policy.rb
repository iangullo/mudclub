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
# app/policies/membership_policy.rb

class MembershipPolicy < ApplicationPolicy
	def initialize(actor, record: nil, kind: nil, club: nil)
		super(actor, record:)
		@target_kind = @record&.kind || kind.presence
		@target_club = @record&.club || club.presence
	end

	#
	# Visibility
	#

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

	def create?
		allowed?(
			same_club?(@target_club) &&
			can_manage_kind?(@target_kind)
		)
	end

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
			when :athlete
				coach? || manages_club?(@target_club)

			when :coach
				coach? ||
				manages_coaches?(@target_club) ||
				manages_club?(@target_club)

			when :volunteer
				manages_club?(@target_club)

			when :board_member, :club_manager
				manages_club?(@target_club)

			else
				false
			end
		end

		def can_manage_kind?(kind)
			return false unless kind

			case kind.to_sym
			when :athlete
				manages_athletes?(@target_club)

			when :coach
				manages_coaches?(@target_club)

			when :volunteer
				manages_club?(@target_club)

			when :board_member, :club_manager
				manages_board?(@target_club)

			else
				false
			end
		end
end
