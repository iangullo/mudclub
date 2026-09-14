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
# app/policies/club_policy.rb
class ClubPolicy < ApplicationPolicy
	#------------------------------------
	# Clubs index - admins or check rivals
	#------------------------------------
	def index?
		allowed?(manages_club?(@club))
	end

	#------------------------------------
	# CRUD
	#------------------------------------

	def show?
		true
	end

	def show_details?
		same_club?(@record)
	end

	def create?
		admin?
	end
	alias new? create?

	def update?
		allowed?(manages_club?(@record))
	end
	alias edit? update?

	def destroy?
		admin? && (actor_club&.id != @record&.id)
	end

	#------------------------------------
	# Administrative capabilities
	#------------------------------------

	def manage_members?
		allowed?(manages_club?(@record))
	end

	alias manage_assignments?  manage_members?
	alias manage_documents?    manage_members?
	alias manage_events?       manage_members?
	alias manage_registrations? manage_members?
	alias manage_teams?        manage_members?
end
