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
	MANAGING_BOARD_KINDS    = %i[president vice_president].freeze
	MANAGING_CLUB_KINDS     = %i[president vice_president secretary club_manager].freeze
	MANAGING_TEAM_KINDS     = %i[head_coach assistant_coach team_manager].freeze
	MANAGING_COACHES_KINDS  = %i[club_manager coaching_coordinator].freeze
	MANAGING_ATHLETES_KINDS = %i[club_manager coaching_coordinator].freeze
	COACHING_TEAM_KINDS     = %i[head_coach assistant_coach].freeze

	def initialize(actor, record: nil, club: nil, token: nil)
		if record && !record.is_a?(self.class.record_class)
			raise ArgumentError,
						"#{self.class} expected #{self.class.record_class}, got #{record.class}"
		end

		@actor       = actor
		@record      = record
		@target_club = club
		@token       = token
		raise ArgumentError, "club must be a Club, got #{club.class}" if club && !club.is_a?(Club)
	end

	def target_club = @target_club

	# Derives the expected record class from the policy name:
	#   DrillPolicy  → Drill
	#   DocumentPolicy → Document
	def self.record_class
		name.delete_suffix("Policy").constantize
	end

	private
		#------------------------
		# Identity
		#------------------------
		def actor_person = @actor&.person
		def admin?       = @actor&.system_admin?

		def same_person?(object)
			actor_person&.id == object&.person&.id
		end

		def record_in_target_club?
			return false unless @target_club && @record
			return false unless @record.respond_to?(:club_id)
			@record.club_id == @target_club.id
		end

		def same_club?(object)
			return false unless actor_person && object

			club = object.is_a?(Club) ? object : object.club
			return false unless club

			actor_person.member_of?(club)
		end

		#------------------------
		# Membership checking
		#------------------------
		def memberships_for(club = @target_club)
			return Membership.none unless club.is_a?(Club) && actor_person

			actor_person.memberships.current.for_club(club)
		end

		def has_membership?(kinds, club = @target_club)
			return false unless club.is_a?(Club) && actor_person
			actor_person.has_membership?(kinds, club)
		end

		def athlete?(club = @target_club)      = actor_person&.is_athlete?(club)
		def coach?(club = @target_club)        = actor_person&.is_coach?(club)
		def volunteer?(club = @target_club)    = actor_person&.is_volunteer?(club)
		def secretary?(club = @target_club)    = actor_person&.is_secretary?(club)
		def club_manager?(club = @target_club) = actor_person&.is_manager?(club)
		def board_member?(club = @target_club) = actor_person&.is_board_member?(club)

		#------------------------
		# Assingment checking
		#------------------------
		def assignments_for(club = @target_club)
			return Assignment.none unless club.is_a?(Club) && actor_person

			Assignment.joins(:membership).where(memberships: {
				person_id: actor_person.id,
				club_id: club.id
			}).current
		end

		def has_club_assignment?(club = @target_club, kinds: nil)
			return false unless club.is_a?(Club) && actor_person
			scope = assignments_for(club).club_level
			scope = scope.of_kind(kinds) if kinds.present?
			scope.exists?
		end

		def has_team_assignment?(team, kinds: nil)
			return false unless team.is_a?(Team)
			scope = assignments_for(team.club).where(team:)
			scope = scope.of_kind(kinds) if kinds.present?
			scope.exists?
		end

		#------------------------
		# Business capabilities
		#------------------------
		def allowed?(condition)
			admin? || condition
		end

		def coaches_team?(team)
			has_team_assignment?(team, kinds: COACHING_TEAM_KINDS)
		end

		def manages_club?(club)
			has_club_assignment?(club, kinds: MANAGING_CLUB_KINDS)
		end

		def manages_board?(club)
			has_club_assignment?(club, kinds: MANAGING_BOARD_KINDS)
		end

		def manages_athletes?(club)
			has_club_assignment?(club, kinds: MANAGING_ATHLETES_KINDS)
		end

		def manages_coaches?(club)
			has_club_assignment?(club, kinds: MANAGING_COACHES_KINDS)
		end

		def manages_team?(team)
			has_team_assignment?(team, kinds: MANAGING_TEAM_KINDS)
		end

		def manages_person?(person)
			return false unless person.is_a?(Person) && target_club
			manages_club?(target_club) && person.member_of?(target_club)
		end

		def managing_club_assignment(club = @target_club)
			return nil unless club.is_a?(Club) && actor_person

			assignments_for(club).club_level.of_kind(MANAGING_CLUB_KINDS).first
		end

		# True when the current request carries a valid requester token —
		# regardless of whether a User is signed in. Used by policies that
		# authorize both authenticated and anonymous actors.
		def requester?
			@actor.nil? && @token.present?
		end
end
