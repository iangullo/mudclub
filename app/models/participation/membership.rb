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

	delegate :email,
					:name,
					:nick,
					:phone,
					:picture,
					:s_name,
					:surname,
					:to_s,
					to: :person,
					allow_nil: true

	#
	# Predicates
	#

	def current?(date = Date.current)
		status.to_sym != :terminated &&
			joined_on <= date &&
			(left_on.nil? || left_on >= date)
	end

	alias active? current?

	def started?
		joined_on.present?
	end

	def open?
		left_on.nil?
	end

	def duration
		return nil unless joined_on

		(left_on || Date.current) - joined_on
	end

	def overlaps?(other)
		return false unless person == other.person
		return false unless club_id == other.club_id
		return false unless kind == other.kind

		end_a = left_on || Date::Infinity.new
		end_b = other.left_on || Date::Infinity.new

		joined_on <= end_b &&
			other.joined_on <= end_a
	end

	def date_range
		"#{joined_on} – #{left_on || I18n.t('shared.status.values.active.label.single')}"
	end

	def terminate!(date = Date.current)
		transaction do
			current_assignments.find_each do |assignment|
				assignment.terminate!(date)
			end

			update!(left_on: date, status: :terminated)
		end
	end

	# -------------------------------------------------------------------------
	# Controller façade method
	# -------------------------------------------------------------------------

	def self.search(search: nil, club:, kind: nil, history: false)
		scope = for_club(club)
		scope = scope.current unless history
		scope = scope.of_kind(kind) if kind.present?
		scope = scope.search_text(search) if search.present?
		scope
	end
end
