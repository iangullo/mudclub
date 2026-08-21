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
# View helpers for MudClub Assignment views
module AssignmentsHelper
  def assignment_context(assignment = @assignment)
    {
      club: assignment.club,
      member: assignment.membership,
      team: assignment.team,
      membership_kind: Catalog::AssignmentKinds.membership_kind(assignment.kind)
    }
  end

  # return Assingments table - context -aware for :member, :team or :club scopes
  def assignments_table(assignments = @assignments)
    { title: assignments_table_title, rows: assignments_table_rows(assignments) }
  end

  def assignments_table_title(manage: false)
      title = [
        { kind: :normal, value: Assignment.fld(:kind, :short) },
        { kind: :normal, value: Assignment.fld(@team ? :team : :role) },
        { kind: :normal, value: Assignment.fld(:starts_on, :short) },
        { kind: :normal, value: Assignment.fld(:status) }
      ]


    # optional button to add new Assignment - should be controlled by Assignment policy, not this old control...
    title << button_field({ kind: :add, url: new_assignment_path, frame: "modal" }) if club_manager?
  end

  def assignments_table_rows(assignments = @assignments)
      rows = Array.new
      assignments.reorder(:starts_on).each { |assignment|
        row = { url: assignment_path(assignment), items: [], frame: :modal }
        row[:items] = [
          participation_kind_field(assignment, class: "border"),
          { kind: :normal, value: assignment.team_id ? assignment.team.to_s : assignment.membership.club.nick },
          { kind: :normal, value: assignment.starts_on },
          participation_status_field(assignment, f_opts: { align: "center", class: "align-top border" })
        ]
        rows << row
      }
      rows
  end

  def assignment_show_fields(assignment = @assignment)
    [
      [
        { kind: :label, value: "#{assignment.fld(:status)}: ", align: "left" },
        gap_field,
        { kind: :label, value: "#{assignment.fld(:starts_on, :short)}: ", align: "left" },
        { kind: :string, value: date_string(assignment.starts_on), cols: 3, align: "left", class: "items-center" }
      ],
      [
        { kind: :string, value: assignment.status_label, align: "center" },
        gap_field,
        { kind: :label, value: "#{assignment.fld(:ends_on, :short)}: ", align: "left" },
        { kind: :string, value: date_string(assignment.ends_on), cols: 3, align: "left", class: "items-center" }
      ],
      [
        { kind: :label, value: "#{assignment.fld(:notes)}: ", align: "left" },
        { kind: :text_field, value: assignment.notes, align: "left" }
      ]
    ]
  end

  def assignment_form_title(assignment, action, title: nil)
    title  = Assignment.act(action.to_sym)
    header = person_form_title(
        assignment,
        icon: assignment.picture,
        title:,
        sex: true
      )
    header[0].pop
    header[2] += [
      gap_field,
      { kind: :label, value: "Fistro Diodenarl", cols: 3 }
    ]
    header
  end

  def assignment_form_fields(assignment = @assignment)
    [
      [ { kind: :label, value: Membership.fld(:notes) } ],
      [
        { kind: :rich_text_area, key: :notes, cols: 3 },
        { kind: :hidden, key: :kind, value: assignment.kind },
        { kind: :hidden, key: :membership_id, value: assignment.membership_id }
      ]
    ]
  end

  def edit_assignment_path(assignment = @assignment, status: false)
    options = { rdx: @rdx, status: }.compact
    polymorphic_path([ :edit, *resource_route(assignment) ], options)
  end

  def new_assignment_path(origin: :club, club: @club, team: @team, membership_kind: nil)
    options = { rdx: @rdx, membership_kind: membership_kind }.compact

    case origin
    when :team
      new_club_team_assignment_path(club, team, options)
    when :club
      new_club_assignment_path(club, options)
    else
      raise ArgumentError, "Invalid origin: #{origin}"
    end
  end

  def assignment_return_path(assignment = @assignment, origin: participation_origin)
    participation_index_path(
      origin:,
      club: assignment.club,
      team: assignment.team,
      membership_kind: Catalog::AssignmentKinds.membership_kind(assignment.kind),
    )
  end
end
