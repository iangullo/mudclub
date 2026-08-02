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

	belongs_to :membership
	belongs_to :team, optional: true

	#
	# Convenient delegation
	#

	delegate :club,
					:person,
					to: :membership

	delegate :name,
					:surname,
					:email,
					:phone,
					:to_s,
					to: :person

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

	# Status of the assignment
	enum :status,
			{
				pending: 0,
				active: 1,
				suspended: 2,
				terminated: 3
			},
			prefix: true

	#
	# Behaviour
	#

	def current?
		starts_on <= Date.current &&
			(ends_on.nil? || ends_on >= Date.current)
	end

	def club_assignment?
		team.nil?
	end

	def team_assignment?
		team.present?
	end

	def terminate!(date = Date.current)
		update!(ends_on: date)
	end
end
