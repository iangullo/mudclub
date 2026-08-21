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
# app/helpers/routing_helper.rb
module RoutingHelper
  # ------------------------------------------------------------
  # Generic route builder – returns the resource array for polymorphic_path
  # ------------------------------------------------------------
  def resource_route(record, action: nil)
    case record
    when Assignment
      if record.team.present?
        [ record.club, record.team, record ]
      else
        [ record.club, record.membership, record ]   # membership-level assignment
      end
    when Membership
      [ record.club, record ]
    when Team
      [ record.club, record ]
    when Event
      if record.team.present?
        [ record.club, record.team, record ]
      else
        [ record.club, record ]
      end
    when Slot
      [ record.club, record ]   # Slots are directly under club
    else
      [ record ]                # fallback
    end
  end

  # ------------------------------------------------------------
  # Specific path helpers with optional `rdx` parameter
  # ------------------------------------------------------------
  def path_for(record, action: nil, rdx: nil)
    base = resource_route(record)
    options = { rdx: rdx }.compact

    if action
      polymorphic_path([ action, *base ], options)
    else
      polymorphic_path(base, options)
    end
  end

  # ------------------------------------------------------------
  # Convenience methods – keep your existing API for consistency
  # ------------------------------------------------------------
  def assignment_path(assignment = @assignment, rdx: @rdx)
    path_for(assignment, rdx:)
  end

  def membership_path(membership = @membership, rdx: @rdx)
    path_for(membership, rdx:)
  end

  def team_path(team = @team, rdx: @rdx)
    path_for(team, rdx:)
  end

  def event_path(event = @event, rdx: @rdx)
    path_for(event, rdx:)
  end

  def slot_path(slot = @slot, rdx: @rdx)
    path_for(slot, rdx:)
  end
end
