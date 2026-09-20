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
# app/policies/home_policy.rb
class HomePolicy < ApplicationPolicy
	#------------------------------------
	# Slot index - timetable
	#------------------------------------
	def index?
		true # routing handled in controller for now
	end
	alias about? index?

	#------------------------------------
	# custom rules
	#------------------------------------
	def log?
		allowed?(manages_club?(target_club))
	end

	def server?
		admin?
	end
	alias clear? server?

	def manages_club?
		super(target_club)
	end

	def club_member?
		same_club?(target_club)
	end
end
