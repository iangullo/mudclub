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
# app/policies/team_policy.rb

class TeamPolicy < ApplicationPolicy
	def initialize(actor, record: nil, club: nil)
		super(actor, record:, club: @record&.club || club)
	end

	#------------------------------------
	# Teams index
	#------------------------------------
	def index? = allowed?(same_club?(target_club))

	#------------------------------------
	# Team object
	#------------------------------------
	def show? = allowed?(same_club?(@record))

	def create? = allowed?(manages_club?(target_club))
	alias new? create?

	def update?
		allowed?(
			manages_club?(@record&.club) ||
			manages_team?(@record)
		)
	end
	alias edit? update?

	def destroy? = allowed?(manages_club?(target_club))

	#------------------------------------
	# General Team information
	#------------------------------------
	def roster?
		allowed?(
			team_member? ||
			coaches_club?(@record&.club) ||
			manages_club?(@record&.club)
		)
	end

	def attendance?
		allowed?(
			team_staff? ||
			coaches_club?(@record&.club) ||
			manages_club?(@record&.club)
		)
	end

	def events?
		allowed?(
			team_member? ||
			coaches_club?(@record&.club) ||
			manages_club?(@record&.club)
		)
	end

	def slots? = allowed?(same_club?(@record))

	#------------------------------------
	# Team coaching
	#------------------------------------
	def plan?
		allowed?(
			coaches_club?(@record&.club) ||
			manages_club?(@record&.club)
		)
	end

	def edit_plan?
		allowed?(
			coaches_team?(@record) ||
			manages_club?(@record&.club)
		)
	end

	def targets?
		allowed?(
			coaches_club?(@record&.club) ||
			manages_club?(@record&.club)
		)
	end

	def edit_targets?
		allowed?(
			coaches_team?(@record) ||
			manages_club?(@record&.club)
		)
	end

	#------------------------------------
	# Team management
	#------------------------------------
	def edit_roster? = allowed?(manages_roster?)

	def view_details?
		allowed?(coaches_team?(@record) || manages_club?(@record&.club))
	end

	private

		# Membership in current team
		def team_member? = has_team_assignment?(@record)

		# Coaching roles in current team
		def team_staff?
			coaches_team?(@record) ||
				has_team_assignment?(@record, kinds: :team_manager)
		end

		# has an active coaching assingment
		def coaches_club?(club) = has_membership?(:coach, club)

		# Who may change the roster?
		def manages_roster?
			manages_club?(@record&.club) ||
				has_club_assignment?(@record&.club, kinds: :coaching_coordinator) ||
				has_team_assignment?(@record, kinds: :head_coach)
		end
end
