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
# app/policies/document_policy.rb
class DocumentPolicy < ApplicationPolicy
	#------------------------------------
	# Create right context
	#------------------------------------
	def initialize(actor, record: nil, club: nil, owner: nil)
		super(actor, record:, club:)
		@owner = owner
	end


	#------------------------------------
	# Documents index - Club managers or Registration requesters
	#------------------------------------
	def index? = manage_or_owner?

	#------------------------------------
	# CRUD Operations
	#------------------------------------
	def show? = manage_or_owner?
	alias show_details? show?

	def create? = manage_or_owner?
	alias new? create?

	def update? = manage_or_owner?
	alias edit? update?

	def destroy? = manage_or_owner?

	private

	def manage_or_owner?
		case @owner
		when Club
			manages_club?(@owner)
		else
			same_person?(@owner)
		end
	end
end
