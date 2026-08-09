# MudClub - Modular Rails application for managing sports clubs.
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
#
# Assignment
#
# Assigns a Club Member to perform a specific Role either
# at Club level or within a Team.
#
class Assignment < ApplicationRecord
	localized_as "participation.assignment"
	include Auditable
	include Participatory

	belongs_to :membership
	belongs_to :team, optional: true

	# attachment of notes to be handled
	has_rich_text :notes

	# assignment-specific picture can be taken
	has_one_attached :avatar

	# Membership kinds identify the reason why a person belongs to a club.
	# Operational responsibilities are modelled through Participation::Assignment.
	enum :kind,
			Catalog::AssignmentKinds.enum,
			prefix: true

	#
	# Convenient delegations
	#
	delegate :club,	:club_id,
					:person, :person_id,
					:birthday,
					:email,
					:female,
					:name,
					:nick,
					:phone,
					:relationships,
					:surname,
					:to_s,
					to: :membership

	#
	# Validations
	#
	validates :starts_on, presence: true
	validates :kind, presence: true
	validate :team_required
	#
	# Scopes
	#
	scope :active, -> {
		where(ends_on: nil)
	}

	scope :of_kind, ->(kind) { where(kind:) }

	scope :current, ->(date = Date.current) {
		where("starts_on <= ?", date)
			.where("ends_on IS NULL OR ends_on >= ?", date)
	}

	scope :open, -> { where(ends_on: nil) }

	scope :club_level, -> {
		where(team_id: nil)
	}

	scope :team_level, -> {
		where.not(team_id: nil)
	}

	scope :search_text, ->(text) {
		return all unless text.present?

		joins(membership: :person)
			.where(memberships: { person_id: Person.search(text) })
	}

	# short name for form viewing
	def s_name
		person&.s_name || Catalog::AssignmentKinds.val(kind)
	end

	# personal photo or membership kind symbol
	def picture
		avatar.attached? ? avatar : membership.picture
	end

	def kind_image
		Catalog::AssignmentKinds.normalize(kind) || :person
	end

	def kind_label(...)
		Catalog::AssignmentKinds.val(kind, ...)
	end

	#
	# Behaviour
	#
	def club_assignment?
		team.nil?
	end

	def team_assignment?
		team.present?
	end

	def belongs_to_team?(team)
		team_id == team&.id
	end

	def modified?
		self.changed? ||
			avatar.attachment_changes.present? ||
			person.modified?
	end

	def rebuild(data)
		# only needed for new records
		self.membership_id ||= data[:membership_id]   if data[:membership_id].present?

		self.team_id   = data[:team_id]   if data.key?(:team_id)
		self.kind      = data[:kind]      if data.key?(:kind)
		self.status    = data[:status]    if data.key?(:status)
		self.starts_on = data[:starts_on] if data.key?(:starts_on)
		self.ends_on   = data[:ends_on]   if data.key?(:ends_on)
		self.notes     = data[:notes]     if data.key?(:notes)

		self.update_attachment("avatar", data[:avatar])			if data[:avatar].present?

		person.rebuild(data[:person_attributes]) if data[:person_attributes]
		self
	end

	def reinstate!(date = Date.current)
		return false unless can_transition_to?(:active)

		transition_to!(:active, :reinstate, date)
	end

	def terminate!(date = Date.current)
		return false unless can_transition_to?(:terminated)

		transition_to!(:terminated, :terminate, date)
	end

	# -------------------------------------------------------------------------
	# Controller façade methods
	# -------------------------------------------------------------------------
	def self.search(club:, search: nil, member: nil, team: nil, kind: nil, history: false)
		scope = team.present? ? where(team_id: team.id) : all
		scope = scope.where(membership_id: member.id) if member.present?
		scope = scope.of_kind(kind) if kind.present?
		scope = scope.search_text(search) if search.present?
		scope = scope.current unless history
		scope
	end

	def self.kind_image(kind)
		Catalog::AssignmentKinds.normalize(kind) || :person
	end

	def self.kind_label(kind, ...)
		Catalog::AssignmentKinds.val(kind, ...)
	end

	private
		# validate coherent team defined for assignment
		def team_required
			if Catalog::AssignmentKinds.team_level?(kind) && team.blank?
				errors.add(:team, :blank)
			end

			if Catalog::AssignmentKinds.club_level?(kind) && team.present?
				errors.add(:team, :invalid)
			end
		end
end
