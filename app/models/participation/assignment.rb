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

	# Membership kinds identify the reason why a person belongs to a club.
	# Operational responsibilities are modelled through Participation::Assignment.
	enum :kind,
			Catalog::AssignmentKinds.enum,
			prefix: true

	#
	# Convenient delegation
	#

	delegate :club,
					:person,
					:name,
					:surname,
					:email,
					:phone,
					:to_s,
					:female,
					to: :membership

	#
	# Validations
	#

	validates :starts_on, presence: true
	validates :kind, presence: true

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

	scope :club_level, -> {
		where(team_id: nil)
	}

	scope :team_level, -> {
		where.not(team_id: nil)
	}

	# short name for form viewing
	def s_name
		person&.s_name || Catalog::AssignmentKinds.val(kind)
	end

	# personal photo or membership kind symbol
	def picture
		return person.avatar if person.avatar

		# if no attached avatar, return the symbol name
		# to be rendered as: symbol_field(symbol)
		kind_image
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

	def terminate!(date = Date.current)
		update!(ends_on: date, status: :terminated)
	end
end
