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
			membership_kind: Assignment.kind_catalog.membership_kind(assignment.kind)
		}
	end

	# return a User or Member assignment history table
	def assignment_history_table(kind, positions)
		kind = kind.to_sym
		{ title: assignment_history_header(kind), rows: assignment_history_rows(kind, positions) }
	end

	# return Assignments table
	def assignments_table(assignments = @assignments)
		participation_table(assignments.reorder(:starts_on), kind: @kind)
	end

	def assignment_show_fields(assignment = @assignment)
		fields = [
			[
				{ kind: :label, value: "#{assignment.fld(:starts_on, :short)}: ", align: :right },
				{ kind: :string, value: date_string(assignment.starts_on), cols: 3, align: :left, class: "items-center" }
			]
		]
		fields <<  [
			{ kind: :label, value: "#{assignment.fld(:ends_on, :short)}: ", align: :right },
			{ kind: :string, value: date_string(assignment.ends_on), cols: 3, align: :left, class: "items-center" }
		] if assignment.ends_on

		fields << [
			{ kind: :label, value: "#{assignment.fld(:notes)}: ", align: :right },
			{ kind: :text_field, value: assignment.notes, align: :left }
		]
	end

	def assignment_form_title(assignment, action, title: nil)
		title  = assignment.membership.kind_label
		header = person_form_title(
				assignment,
				icon: assignment.picture,
				title:,
				sex: true
			)
		header
	end

	def assignment_form_fields(assignment = @assignment)
		[
			[ { kind: :label, value: Membership.fld(:notes) } ],
			[
				{ kind: :rich_text_area, key: :notes, cols: 3 },
				{ kind: :hidden, key: :membership_id, value: assignment.membership_id }
			]
		]
	end

	def assignment_form_kind_fields(assignment = @assignment)
		m_kind  = (@member ? @member.kind : assignment.membership.kind)&.to_sym
		m_scope = @team ? :team : :club
		options = assignment.kind_options(scope: m_scope, membership: m_kind, selectable: true)
		[
			[
				gap_field(size: 6),
				{ kind: :label, value: Assignment.fld(:kind, :short) },
				gap_field(size: 1),
				{ kind: :select_collection, key: :kind, options:, value: assignment.kind&.to_sym }
			]
		]
	end

	def edit_assignment_path(assignment = @assignment, status: false)
		options = { rdx: @rdx, status: }.compact
		polymorphic_path([ :edit, *resource_route(assignment) ], options)
	end

	def new_assignment_path(club: @club, team: @team, membership_kind: nil)
		options = { rdx: @rdx, membership_kind: membership_kind }.compact

		if team.present?
			new_club_team_assignment_path(team.club, team, options)
		elsif club.present?
			new_club_assignment_path(club, options)
		else
			raise ArgumentError, "Invalid scope to create assignment (club: #{club&.id}; team: #{team&.id}"
		end
	end

	def assignment_return_path(assignment = @assignment)
		return_path_for(
			assignment,
			kind: assignment.membership.kind,
			search: params[:search].presence
		)
	end

	def assignments_base_path
		if @team
			club_team_path(@club, @team, rdx: @rdx)
		elsif @user
			user_path(@user, rdx: @rdx)
		else
			club_path(@club, rdx: @rdx)
		end
	end

	private

		# p_class should be Membership or Assignment - maybe Registration in future
		def assignment_history_header(kind)
			case kind
			when :athlete
				header = [
					{ kind: :normal, value: Assignment.fld(:number, :short) },
					{ kind: :normal, value: Team.label }
				]
			when :coach
				header = [
					{ kind: :normal, value: Team.label },
					{ kind: :normal, value: Assignment.fld(:role) }
				]
			else
				header = [ { kind: :normal, value: Assignment.fld(:role) } ]
			end

			header += [
				{ kind: :normal, value: Assignment.fld(:start_on, :short) },
				{ kind: :normal, value: Assignment.fld(:status) }
			]
		end

		def assignment_history_rows(kind, positions)
				rows = Array.new
				positions.each do |position|
					row   = { url: path_for(position.assigned_to, rdx: 3), items: [] }
					case kind
					when :athlete
						row[:items] << { kind: :normal, value: position.number }
						row[:items] << { kind: :normal, value: position.team.name }
					when :coach
						row[:items] << { kind: :normal, value: position.team.name }
						row[:items] << { kind: :normal, value: position.kind_label }
					else
						row[:items] << { kind: :normal, value: position.kind_label }
					end
					row[:items] << { kind: :normal, value: position.starts_on }
					row[:items] << participation_status_field(position, f_opts: { align: :center, class: "border" })
					rows << row
				end
				rows
		end
end
