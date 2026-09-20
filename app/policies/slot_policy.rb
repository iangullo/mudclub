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
# app/policies/slot_policy.rb
class SlotPolicy < ApplicationPolicy
	#------------------------------------
	# Slot index - timetable
	#------------------------------------
	def index?
		allowed?(manages_club?(target_club))
	end

	#------------------------------------
	# CRUD
	#------------------------------------

	def show?
		@record && allowed?(manages_club?(target_club))
	end

	def create?
		allowed?(manages_club?(target_club))
	end
	alias new? create?

	def update?
		@record && allowed?(manages_club?(target_club))
	end
	alias edit? update?

	def destroy?
		@record && allowed?(manages_club?(target_club))
	end
end
