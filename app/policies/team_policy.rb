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
		super(actor, record:)

		@record      = record
		@target_club = club || @record&.club
	end

	#
	# CRUD
	#
	def index?
		allowed?(has_club_assignment?(@target_club))
	end

	def show?
		allowed?(team_member?)
	end

	def create?
		allowed?(manages_club?(@target_club))
	end

	def update?
		allowed?(manages_club?(@target_club))
	end

	def destroy?
		allowed?(manages_club?(@target_club))
	end

	#
	# Team pages
	#
	def roster?
		allowed?(team_member?)
	end

	def attendance?
		allowed?(team_member?)
	end

	def events?
		allowed?(team_member?)
	end

	def plan?
		allowed?(team_member?)
	end

	def targets?
		allowed?(team_member?)
	end

	def slots?
		allowed?(team_member?)
	end

	#
	# Team management
	#
	def edit_roster?
		allowed?(manages_roster?)
	end

	def edit_plan?
		allowed?(coaches_team_here?)
	end

	def edit_targets?
		allowed?(coaches_team_here?)
	end

	private

		#
		# Membership in current team
		#
		def team_member?
			has_team_assignment?(@record)
		end

		#
		# Coaching roles in current team
		#
		def coaches_team_here?
			coaches_team?(@record)
		end

		#
		# Management roles in current team
		#
		def manages_team_here?
			manages_team?(@record)
		end

		#
		# Who may change the roster?
		#
		def manages_roster?
			manages_athletes?(@target_club) ||
			manages_team_here?
		end
end
