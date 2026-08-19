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
# Associates Assignments with Events.
#
# This model replaces the legacy EventsPlayers driven model
#
class Attendance < ApplicationRecord
  localized_as "calendar.attendance"

  #-------------------------------------
  # Associations
  #-------------------------------------
  belongs_to :event
  belongs_to :assignment

  # Delegations for convenience
  delegate :person, :team, :club, to: :assignment, allow_nil: true
  delegate :name, :s_name, to: :person, allow_nil: true, prefix: true

  #-------------------------------------
  # Enums
  #-------------------------------------
  enum :status, %i[unknown present absent excused late], default: :unknown

  #-------------------------------------
  # Validations
  #-------------------------------------
  validates :event, :assignment, presence: true
  validates :assignment_id, uniqueness: { scope: :event_id }

  #-------------------------------------
  # Scopes
  #-------------------------------------
  scope :for_event, ->(event) { where(event_id: event.id) }
  scope :for_team, ->(team) { joins(:event).where(events: { team_id: team.id }) }
  scope :for_assignment, ->(assignment) { where(assignment_id: assignment.id) }
  scope :for_membership_kind, ->(kind) {
    joins(assignment: :membership)
      .where(memberships: { kind: })
  }
  scope :for_role, ->(kind) { for_membership_kind(kind) }
  scope :matches, -> { joins(:event).merge(Event.matches.chronological) }
  scope :trainings, -> { joins(:event).merge(Event.trainings.chronological) }
  scope :last7, -> { joins(:event).merge(Event.last7.chronological) }
  scope :last30, -> { joins(:event).merge(Event.last30.chronological) }
  scope :present, -> { where(status: :present) }
  scope :absent, -> { where(status: :absent) }
  scope :late, -> { where(status: :late) }
  scope :excused, -> { where(status: :excused) }

  #-------------------------------------
  # Class methods
  #-------------------------------------
  def self.count_by_event(event, role: nil)
    scope = where(event_id: event.id)
    scope = scope.for_role(role) if role
    scope.count
  end

  def self.fetch(event, assignment, create: false)
    find_or_initialize_by(event_id: event.id, assignment_id: assignment.id).tap do |record|
      record.save if create && record.new_record?
    end
  end

  def self.prepare(event, assignment)
    fetch(event, assignment, create: true)
  end
end
