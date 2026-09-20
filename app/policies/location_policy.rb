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
# app/policies/location_policy.rb
class LocationPolicy < ApplicationPolicy
	#------------------------------------
	# Division index - admins
	#------------------------------------
	def index?
		location_manager?
	end

	#------------------------------------
	# CRUD
	#------------------------------------

	def show?
		@record && @actor.is_a?(User)
	end

	def create?
		location_manager?
	end
	alias new? create?

	def update?
		@record && location_manager?
	end
	alias edit? update?

	def destroy?
		@record && admin?
	end

	private
		def location_manager?
			return admin? unless target_club
			manages_club?(target_club)
		end
end
