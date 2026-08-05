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
	localized_as "participation.membership"
	include Auditable
	include Participatory

	belongs_to :club
	belongs_to :person
	accepts_nested_attributes_for :person

	# A Club member can have multiple assignments over time or simultaneously.
	has_many :assignments,
					dependent: :restrict_with_exception

	# attachment of notes to be handled
	has_rich_text :notes

	# Membership kinds identify the reason why a person belongs to a club.
	# Operational responsibilities are modelled through Participation::Assignment.
	enum :kind,
			Catalog::MembershipKinds.enum,
			prefix: true

	validates :kind,
						:status,
						:joined_on,
						presence: true

	validate :kind_cannot_change, on: :update

	# -------------------------------------------------------------------------
	# Time scopes
	# -------------------------------------------------------------------------

	scope :current, -> {
		where("joined_on <= ?", Date.current)
			.where("left_on IS NULL OR left_on >= ?", Date.current)
			.where(status: :active)
	}

	scope :open, -> { where(left_on: nil) }

	scope :historical, -> { where.not(left_on: nil) }

	# -------------------------------------------------------------------------
	# Business scopes
	# -------------------------------------------------------------------------

	scope :for_club, ->(club) {
		club.present? ? where(club:) : all
	}

	scope :of_kind, ->(kind) {
		kind.present? ? where(kind:) : all
	}

	# -------------------------------------------------------------------------
	# Text search scope
	# -------------------------------------------------------------------------

	scope :search_text, ->(text) {
		if text.present?
			joins(:person)
				.where(person_id: Person.search(text))
		else
			all
		end
	}

	delegate :avatar,
					:birthday,
					:email,
					:female,
					:name,
					:nick,
					:phone,
					:relationships,
					:surname,
					:to_s,
					to: :person,
					allow_nil: true

	#
	# Predicates
	#

	# short name for form viewing
	def s_name
		person&.s_name || Catalog::MembershipKinds.val(kind)
	end

	# personal photo or membership kind symbol
	def picture
		return person.avatar if person.avatar.attached?

		# if no attached avatar, return the symbol name
		# to be rendered as: symbol_field(symbol)
		kind_image
	end

	def kind_image
		Catalog::MembershipKinds.normalize(kind) || :person
	end

	def kind_label(...)
		Catalog::MembershipKinds.val(kind, ...)
	end

	def overlaps?(other)
		return false unless other
		return false unless person == other.person
		return false unless club_id == other.club_id
		return false unless kind == other.kind

		end_a = left_on || Date::Infinity.new
		end_b = other.left_on || Date::Infinity.new

		joined_on <= end_b &&
			other.joined_on <= end_a
	end

	def modified?
		self.changed? ||
			person.modified?
	end

	def rebuild(data)
		self.club_id   = data[:club_id]   if data.key?(:club_id)
		self.kind      = data[:kind]      if data.key?(:kind)
		self.status    = data[:status]    if data.key?(:status)
		self.joined_on = data[:joined_on] if data.key?(:joined_on)
		self.left_on   = data[:left_on]   if data.key?(:left_on)
		self.notes     = data[:notes]     if data.key?(:notes)

		person.rebuild(data[:person_attributes]) if data[:person_attributes]

		self
	end

	def reinstate!(date = Date.current)
		return false unless can_transition_to?(:active)

		transition_to!(:active, :reinstate, date)
	end

	def terminate!(date = Date.current)
		return false unless can_transition_to?(:terminated)

		transaction do
			# define well this scope for (:active & :suspended)
			assignments.open.find_each do |assignment|
				assignment.terminate!(date)
			end

			transition_to!(:terminated, :terminate, date)
		end

		true
	end

	# -------------------------------------------------------------------------
	# Controller façade methods
	# -------------------------------------------------------------------------

	# accessors for Participatory date names
	def starts_on
		joined_on
	end

	def starts_on=(date)
		self.joined_on = date
	end

	def ends_on
		left_on
	end

	def ends_on=(date)
		self.left_on = date
	end

	def self.search(search: nil, club:, kind: nil, history: false)
		scope = for_club(club)
		scope = scope.current unless history
		scope = scope.of_kind(kind) if kind.present?
		scope = scope.search_text(search) if search.present?
		scope
	end

	def self.kind_image(kind)
		Catalog::MembershipKinds.normalize(kind) || :person
	end

	def self.kind_label(kind, ...)
		Catalog::MembershipKinds.val(kind, ...)
	end

	private
		def kind_cannot_change
			errors.add(:kind, :readonly) if will_save_change_to_kind?
		end
end
