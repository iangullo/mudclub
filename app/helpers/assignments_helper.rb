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
	# return Assingments table - context -aware for :member, :team or :club scopes
	def assignments_table(assignments:, show_from: :member, new_from: :member)
		{ title: assignments_table_title(from: new_from), rows: assignments_table_rows(assignments, from: show_from) }
	end

	def assignments_table_title(from:)
		title = [
			{ kind: :normal, value: Assignment.attr(:kind, :short) },
			{ kind: :normal, value: Assignment.attr((from == :club) ? :role : :team) },
			{ kind: :normal, value: Assignment.attr(:starts_on, :short) },
			{ kind: :normal, value: Assignment.attr(:status) }
		]
		# optional button to add new Assignment - shoudl be controlled by Assignment policy, not this old control...
		title << button_field({ kind: :add, url: new_assignment_path(from:), frame: "modal" }) if club_manager?
	end

	def assignments_table_rows(assignments, from:)
			rows = Array.new
			assignments.reorder(:starts_on).each { |assignment|
				row = { url: assignment_path(assignment, from:), items: [] }

				row[:items] << obj_kind_field(assignment, class: "border")
				row[:items] << { kind: :normal, value: assignment.team_id ? assignment.team.to_s : assignment.member.club.nick }
				row[:items] << { kind: :normal, value: assignment.starts_on }
				row[:items] << obj_status_field(assignment, f_opts: { align: "center", class: "align-top border" })
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

	def assignment_section_assignment_fields(assignment)
		l_since = "#{I18n.t('calendar.fields.since')}: "
		l_since +=
			if assignment.starts_on
				date_string(assignment.starts_on)
			else
				"(#{I18n.t("shared.statuses.pending")})"
			end

		l_until = "#{I18n.t('calendar.fields.until')}: "
		l_until +=
			if assignment.ends_on
				date_string(assignment.ends_on)
			else
				"-"
			end

		[
			[	{ kind: :string, value: l_since, cols: 3, align: "left" }	],
			[ { kind: :string, value: l_until, cols: 3, align: "left" } ]
		]
	end

	def assignment_path(assignment, from: :member)
		case from
		when :member
			club_member_assignments_path(
				assignment.membership.club,
				assignment.membership,
				assignment,
				rdx: @rdx
			)

		when :club
			club_assignments_path(
				assignment.membership.club,
				assignment,
				rdx: @rdx
			)

		when :team
			club_member_assignments_path(
				assignment.membership.club,
				assignment,
				team_id: assignment.team.id,
				rdx: @rdx
			)
		end
	end

	def new_assignment_path(from:)
		case from
		when :club
			new_club_assignment_path(
				@club,
				rdx: @rdx
			)

		when :member
			new_club_member_assignment_path(
				@club,
				@member,
				rdx: @rdx
			)

		when :team
			new_club_assignment_path(
				@club,
				team_id: @team.id,
				rdx: @rdx
			)
		end
	end

	def edit_assignment_path(assignment, from: :member, status: false)
		case from
		when :member
			edit_club_member_assignment_path(
				assignment.membership.club,
				assignment.membership,
				assignment,
				rdx: @rdx
			)

		when :club
			edit_club_assignment_path(
				assignment.membership.club,
				assignment,
				rdx: @rdx
			)

		when :team
			edit_club_member_assignment_path(
				assignment.membership.club,
				assignment.membership,
				assignment,
				team_id: assignment.team.id,
				rdx: @rdx
			)
		end
	end
end
