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
class ApplicationPolicy
	def initialize(actor, record: nil)
		@actor  = actor
		@record = record
	end

	private

	def actor_person
		@actor&.person
	end

	def actor_club
		@actor&.club
	end

	def same_person?(object)
		actor_person&.id == object&.person&.id
	end

	def same_club?(object)
		actor_club&.id == object&.club&.id
	end

	def admin?
		@actor&.admin?
	end

	def memberships_for(club = actor_club)
		return Membership.none unless club && actor_person

		actor_person.memberships.current.for_club(club)
	end

	def has_membership?(kind, club = actor_club)
		memberships_for(club).of_kind(kind).exists?
	end

	[
		:athlete,
		:coach,
		:secretary,
		:club_manager,
		:board_member,
		:volunteer
	].each do |kind|
		define_method("#{kind}?") do |club = actor_club|
			has_membership?(kind, club)
		end
	end

	def allowed?(condition)
		admin? || condition
	end

	def can_manage_club?(club)
		return true if admin?
		return false unless same_club?(club)

		secretary?(club) || club_manager?(club)
	end
end
