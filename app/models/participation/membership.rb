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
# Membership
#
# Represents the long-term relationship between a Person and a Club.
#
# Membership establishes that a person belongs to a club and records
# the administrative reason for that relationship.
#
# Operational responsibilities (athlete, coach, volunteer, etc.) are
# exercised through one or more Assignments.
#
# Memberships are archivable but never deleted in order to preserve
# the historical relationship between clubs and people.
#
class Membership < ApplicationRecord
	belongs_to :person
	belongs_to :club

	# A Club member can have multiple assignments over time or simultaneously.
	has_many :assignments,
					dependent: :restrict_with_exception

	# Membership kinds identify the reason why a person belongs to a club.
	# Operational responsibilities are modelled through Participation::Assignment.
	enum :kind,
			Catalog::MembershipKinds.enum,
			prefix: true

	# Status of the membership
	enum :status,
			{
				pending: 0,
				active: 1,
				suspended: 2,
				terminated: 3
			},
			prefix: true

	validates :kind,
						:status,
						:joined_on,
						presence: true

	scope :current, -> { where(left_on: nil) }

	delegate :email,
					:name,
					:nick,
					:phone,
					:surname,
					:to_s,
					to: :person,
					allow_nil: true

	#
	# Predicates
	#

	def active?
		left_on.nil? && status_active?
	end

	def terminated?
		left_on.present?
	end

	#
	# Assignment helpers
	#

	def current_assignments
		assignments.where(ends_on: nil)
	end

	def assigned_role?(role:, team: nil, on: Date.current)
		assignments
			.where(role:, team:)
			.where("starts_on <= ?", on)
			.where("ends_on IS NULL OR ends_on >= ?", on)
			.exists?
	end

	def available_roles(team: nil)
		roles = club.roles.select do |role|
			role.required_membership == kind.to_sym
		end

		roles.select do |role|
			team.present? ? role.team_scope? : role.club_scope?
		end
	end

	#
	# Lifecycle
	#

	def assign_role(role:, team: nil, starts_on: Date.current)
		errors.clear

		return unless validate_assignment(
			role:,
			team:
		)

		assignments.create!(
			role: role,
			team: team,
			starts_on: starts_on
		)
	end

	def remove_role(role:, team: nil, ends_on: Date.current)
		assignment =
			current_assignments.find_by(
				role: role,
				team: team
			)

		unless assignment
			errors.add(:base, :assignment_not_found)
			return
		end

		assignment.terminate!(ends_on)
	end

	def terminate!(date = Date.current)
		transaction do
			current_assignments.find_each do |assignment|
				assignment.terminate!(date)
			end

			update!(left_on: date)
		end
	end

	def self.kinds
		Catalog::MembershipKinds
	end

	protected

		def label_key
			"participation.membership.kinds.#{kind}"
		end

	private

		def validate_assignment(role:, team:)
			unless active?
				errors.add(:base, :membership_inactive)
				return false
			end

			unless role.club == club
				errors.add(:base, :role_from_other_club)
				return false
			end

			unless role.requires_membership?(kind)
				errors.add(:base, :invalid_membership_kind)
				return false
			end

			if role.club_scope?

				if team.present?
					errors.add(:team, :must_be_blank)
					return false
				end

			else

				if team.blank?
					errors.add(:team, :blank)
					return false
				end

			end

			if assigned?(role:, team:)
				errors.add(:base, :already_assigned)
				return false
			end

			true
		end
end
