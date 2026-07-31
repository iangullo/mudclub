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
		@target_kind = kind.presence || @record&.kind
		@target_club = club.presence || @record&.club
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
			own_membership? || (
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
			same_club?(@record) &&
			can_manage_kind?(@kind)
		)
	end

	[ :edit?, :update?, :terminate? ].each do |action|
		define_method("#{action}?") do
			allowed?(
				same_club?(@record) &&
				can_manage_kind?(@kind)
			)
		end
	end

	private
	def own_membership?
		same_person?(@record)
	end

	def can_view_kind?(kind)
		return false unless kind

		case kind.to_sym
		when :athlete, :coach
			coach? || secretary? || club_manager? || board_member?

		when :volunteer
			secretary? || club_manager? || board_member?

		when :board_member, :club_manager
			board_member?

		else
			false
		end
	end

	def can_manage_kind?(kind)
		return false unless kind

		case kind.to_sym
		when :athlete, :coach, :volunteer
			secretary? || club_manager?

		when :board_member, :club_manager
			board_member?

		else
			false
		end
	end
end
