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
	def assignment_history_table(member)
		kind = member.kind.to_sym
		{ title: assignment_history_header(kind), rows: assignment_history_rows(member, kind) }
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
			{ kind: :string, value: assignment.to_s, cols: 3 }
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
			kind: Assignment.kind_catalog.membership_kind(assignment.kind),
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

		def assignment_history_rows(object, kind)
				rows  = Array.new
				frame = :modal
				object.assignments.order(:starts_on).reverse.each do |position|
					row   = { url: path_for(position.assigned_to, kind:, status: params[:status].presence), items: [], frame: }
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
