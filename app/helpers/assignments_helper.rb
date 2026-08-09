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
	def assignment_context(assignment)
		{
			club: assignment.club,
			member: assignment.membership,
			team: assignment.team,
			membership_kind: Catalog::AssignmentKinds.membership_kind(assignment.kind)
		}
	end

	# return Assingments table - context -aware for :member, :team or :club scopes
	def assignments_table(assignments)
		{ title: assignments_table_title, rows: assignments_table_rows(assignments) }
	end

	def assignments_table_title
		title = [
			{ kind: :normal, value: Assignment.attr(:kind, :short) },
			{ kind: :normal, value: Assignment.attr(@team ? :team : :role) },
			{ kind: :normal, value: Assignment.attr(:starts_on, :short) },
			{ kind: :normal, value: Assignment.attr(:status) }
		]
		# optional button to add new Assignment - shoudl be controlled by Assignment policy, not this old control...
		title << button_field({ kind: :add, url: assignment_new_path, frame: "modal" }) if club_manager?
	end

	def assignments_table_rows(assignments)
			rows = Array.new
			assignments.reorder(:starts_on).each { |assignment|
				row = { url: assignment_show_path(assignment), items: [], frame: :modal }

				row[:items] << participation_kind_field(assignment, class: "border")
				row[:items] << { kind: :normal, value: assignment.team_id ? assignment.team.to_s : assignment.membership.club.nick }
				row[:items] << { kind: :normal, value: assignment.starts_on }
				row[:items] << participation_status_field(assignment, f_opts: { align: "center", class: "align-top border" })
				rows << row
			}
			rows
	end

	def assignment_show_fields(assignment)
		[
			[
				{ kind: :label, value: "#{assignment.attr(:status)}: ", align: "left" },
				gap_field,
				{ kind: :label, value: "#{assignment.attr(:starts_on, :short)}: ", align: "left" },
				{ kind: :string, value: date_string(assignment.starts_on), cols: 3, align: "left", class: "items-center" }
			],
			[
				{ kind: :string, value: assignment.status_label, align: "center" },
				gap_field,
				{ kind: :label, value: "#{assignment.attr(:ends_on, :short)}: ", align: "left" },
				{ kind: :string, value: date_string(assignment.ends_on), cols: 3, align: "left", class: "items-center" }
			],
			[
				{ kind: :label, value: "#{assignment.attr(:notes)}: ", align: "left" },
				{ kind: :text_field, value: assignment.notes, align: "left" }
			]
		]
	end

	def assignment_form_title(assignment, action, title: nil)
		title  = Assignment.t_path(:action, action.to_sym)
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

	def assignment_form_fields(assignment)
		[
			[ { kind: :label, value: Membership.attr(:notes) } ],
			[
				{ kind: :rich_text_area, key: :notes, cols: 3 },
				{ kind: :hidden, key: :kind, value: assignment.kind },
				{ kind: :hidden, key: :membership_id, value: assignment.membership_id }
			]
		]
	end

	def assignment_show_path(assignment)
		club_member_assignment_path(
			assignment.club,
			assignment.membership,
			assignment,
			rdx: @rdx
		)
	end

	def assignment_edit_path(assignment, status: false)
		edit_club_member_assignment_path(
			assignment.club,
			assignment.membership,
			assignment,
			status:,
			rdx: @rdx
		)
	end

	def assignment_new_path(origin: participation_origin, club: @club, team: @team, membership_kind: nil)
		case origin
		when :team
			new_club_team_assignment_path(club, team, membership_kind:, rdx: @rdx)

		when :club
			new_club_assignment_path(club, membership_kind:, rdx: @rdx)
		end
	end

	def assignment_return_path(assignment, origin: participation_origin)
		participation_index_path(
			origin:,
			club: assignment.club,
			team: assignment.team,
			membership_kind: Catalog::AssignmentKinds.membership_kind(assignment.kind),
		)
	end
end
