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
		#------------------------
		# Identity
		#------------------------
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

		#------------------------
		# Membership checking
		#------------------------
		def memberships_for(club = actor_club)
			return Membership.none unless club && actor_person

			actor_person.memberships.current.for_club(club)
		end

		def has_membership?(kinds, club = actor_club)
			memberships_for(club)
				.of_kind(Array(kinds))
				.exists?
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

		#------------------------
		# Assingment checking
		#------------------------
		def assignments_for(club = actor_club)
			return Assignment.none unless club && actor_person

			Assignment
				.joins(:membership)
				.where(memberships: {
					person_id: actor_person.id,
					club_id: club.id
				})
				.current
		end

		def has_assignment?(kinds, club = actor_club)
			assignments_for(club)
				.of_kind(Array(kinds))
				.exists?
		end

		def has_club_assignment?(club = actor_club, kinds = nil)
			scope = assignments_for(club).club_level

			scope = scope.of_kind(Array(kinds)) if kinds.present?

			scope.exists?
		end

		def has_team_assignment?(team, kinds = nil)
			scope = assignments_for(team.club).where(team:)

			scope = scope.of_kind(Array(kinds)) if kinds.present?

			scope.exists?
		end

		#------------------------
		# Business capabilities
		#------------------------
		def allowed?(condition)
			admin? || condition
		end

		def manages_club?(club)
			has_club_assignment?(
				club,
				[
					:president,
					:vice_president,
					:secretary,
					:club_manager
				]
			)
		end

		def manages_board?(club)
			has_club_assignment?(
				club,
				[
					:president,
					:vice_president
				]
			)
		end

		def manages_athletes?(club)
			has_club_assignment?(
				club,
				[ :club_manager, :coaching_coordinator ]
			)
		end

		def manages_coaches?(club)
			has_club_assignment?(
				club,
				[ :club_manager, :coaching_coordinator ]
			)
		end

		def manages_team?(team)
			has_team_assignment?(
				team,
				[
					:head_coach,
					:assistant_coach,
					:team_manager
				]
			)
		end

		def coaches_team?(team)
			has_team_assignment?(
				team,
				[
					:head_coach,
					:assistant_coach
				]
			)
		end
end
