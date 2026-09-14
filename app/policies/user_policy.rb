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
# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
	#------------------------------------
	# User index - admins
	#------------------------------------
	def index?
		admin?
	end

	#------------------------------------
	# CRUD
	#------------------------------------

	def show?
		allowed?(same_person?(@record))
	end

	def show_details?
		allowed?(same_person?(@record))
	end

	def create?
		admin?
	end
	alias new? create?

	def update?
		allowed?(same_person?(@record))
	end
	alias edit? update?

	def destroy?
		admin? && !same_person?(@record)
	end
end
