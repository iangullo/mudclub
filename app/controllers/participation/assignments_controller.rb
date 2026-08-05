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
# Handle Assignment views - always accessed by a assignment, club or team
class AssignmentsController < ApplicationController
	include Filterable
	before_action :set_assignment, only: [ :show, :edit, :update, :terminate ]

	# GET /clubs/x/assignments
	# GET /clubs/x/assignments.json
	def index
		get_context
		@assignment_policy = check_policy!(
			AssignmentPolicy,
			kind: @kind,
			club: @club
		)

		search  = params[:search].presence
		history = search &&  @assignment_policy.history?
		@assignments =
			Assignment.search(
				club: @club,
				kind: @kind,
				search:,
				history:
			)

		title  = prepare_index_title
		page   = paginate(@assignments)	# paginate results
		table  = helpers.assignments_table(assignments: page)
		retlnk = base_lnk(club_path(@clubid, rdx: @rdx))
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /assignments/1
	# GET /assignments/1.json
	def show
		@assignment_policy = check_policy!(AssignmentPolicy, record: @assignment)
		@title  = create_fields(helpers.person_show_participation_title(@assignment, status_url: edit_assignment_path(status: true)))
		@fields = create_fields(helpers.assignment_show_fields(@assignment))
		submit  = edit_club_member_assignment_path(@assignment, rdx: @rdx) if @assignment_policy.update?
		@submit = create_submit(close: :back, retlnk: crud_return, submit:, frame: "modal")
	end

	# GET /assignments/new
	def new
		@assignment_policy = check_policy!(AssignmentPolicy, club: @club, kind: @kind)
	end

	# POST /assignments
	# POST /assignments.json
	def create
		@assignment_policy = check_policy!(AssignmentPolicy, club: @club, kind: @kind)
	end

	# GET /assignments/1/edit
	def edit
		@assignment_policy = check_policy!(AssignmentPolicy, record: @assignment)
	end

	# PATCH/PUT /assignments/1
	# PATCH/PUT /assignments/1.json
	def update
		@assignment_policy = check_policy!(AssignmentPolicy, record: @assignment)
	end

	# DELETE /assignments/1
	# DELETE /assignments/1.json
	def terminate
		@assignment_policy = check_policy!(AssignmentPolicy, record: @assignment)
	end

	private
		# wrapper to set return link for CRUD operations
		def crud_return
			return club_assignments_path(kind: @assignment.kind, search: @assignment.s_name, rdx: @rdx) if @assignment
			(@clubid ? club_assignments_path(@clubid, kind: @kind, rdx: @rdx) : u_path)
		end

		# prepare assignment action context
		def get_assignment_context
			@clubid = @assignment&.club_id
			@kind = @assignment&.kind
		end

		def prepare_index_title
			if @kind
				title = Catalog::AssignmentKinds.val(@kind, :plural)
				concept = @kind
			else
				title = Assignment.label(:plural)
				concept = :person
			end
			title = helpers.person_title(title:, icon: { concept:, options: { namespace: "common", size: "50x50" } })
			fields = [
				{ kind: :search_text, key: :search, placeholder: title, value: params[:search].presence || session.dig("#{@kind}_filters", "search"), size: 10 },
				{ kind: :hidden, key: :kind, value: @kind }
			]
			title << [
				{
					kind: :search_box,
					url: club_assignments_path(@clubid, kind: @kind, rdx: @rdx),
					fields:
				}
			]
		end

		# Prepare a assignment form
		def prepare_form(action)
			@title    = create_fields(helpers.person_form_title(@assignment.person, icon: @assignment.picture, title: Assignment.t_path(:action, action.to_sym), sex: true))
			@a_fields = create_fields(helpers.assignment_form) # pending creation
			@p_fields = create_fields(helpers.person_form(@assignment.person))	# existing in helpers/people_helper
			@parents  = create_fields(helpers.people_form_parents) if @assignment.person.age < 18 # pending review
			@submit   = create_submit
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_assignment
			@assignment = Assignment.find_by_id(params[:id]) unless @assignment&.id==params[:id]
			get_assignment_context
		end

		def get_context
			@club = Club.find(params[:club_id].presence) if params[:club_id].present?
			@kind = Catalog::AssignmentKinds.normalize(params[:kind])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def assignment_params
			params.require(:assignment).permit(
				:id,
				:club_id,
				:person_id,
				:joined_on,
				:left_on,
				:kind,
				:rdx,
				person_attributes: [
					:id,
					:address,
					:avatar,
					:birthday,
					:dni,
					:email,
					:female,
					:id_back,
					:id_front,
					:name,
					:nick,
					:phone,
					:surname
				]
			)
		end
end
