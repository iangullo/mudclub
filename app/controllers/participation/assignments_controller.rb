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
	before_action :load_participation_context
	before_action :load_assignment_kind
	before_action :set_assignment, only: [ :show, :edit, :update, :terminate ]

	# GET /clubs/x/assignments
	# GET /clubs/x/assignments.json
	def index
		@assignment_policy = check_policy!(AssignmentPolicy, kind: @kind, club: @club, team: @team)

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
		retlnk = helpers.assignments_base_path
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /assignments/1
	# GET /assignments/1.json
	def show
		@assignment_policy = check_policy!(AssignmentPolicy, record: @assignment)
		status = @assignment_policy.edit?

		@title  = create_fields(
			helpers.participation_title(
				@assignment,
				status_url: helpers.assignment_edit_path(@assignment, status:),
				just_icon: false
			)
		)
		@fields = create_fields(helpers.assignment_show_fields(@assignment))
		submit  = helpers.assignment_edit_path(@assignment) if @assignment_policy.update?
		@submit = create_submit(submit:, frame: :modal)
	end

	# GET /assignments/new
	def new
		@assignment_policy = check_policy!(AssignmentPolicy, club: @club, kind: @kind)
		prepare_form(:create)
	end

	# POST /assignments
	# POST /assignments.json
	def create
		@assignment_policy = check_policy!(AssignmentPolicy, club: @club, kind: @kind)
		respond_to do |format|
			Assignment.transaction do
				@assignment = Assignment.new(club: @club, team: @team, membership: @member, kind: @kind)
				@assignment.rebuild(assignment_params)
				@assignment.starts_on = Date.today

				if @assignment.save
					format.html do
						redirect_to helpers.assignment_return_path(@assignment), notice: Assignment.msg(:created)
					end

					format.json { render :show, status: :ok, location: helpers.assignment_return_path(@assignment) }
				else
					log_assignment_errors
					raise ActiveRecord::Rollback
				end
			end

			unless @assignment.persisted? && @assignment.errors.empty?
				prepare_form(:create)

				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @assignment.errors, status: :unprocessable_entity }
			end
		end
	end

	# GET /assignments/1/edit
	def edit
		@assignment_policy = check_policy!(AssignmentPolicy, record: @assignment)
		prepare_form(:edit)
	end

	# PATCH/PUT /assignments/1
	# PATCH/PUT /assignments/1.json
	def update
		@assignment_policy = check_policy!(AssignmentPolicy, record: @assignment)

		respond_to do |format|
			Assignment.transaction do
				@assignment.rebuild(assignment_params)

				notice = Assignment.msg(@assignment.modified? ? :updated : :no_change)
				if @assignment.save
					format.html do
						redirect_to helpers.assignment_return_path(@assignment), notice:
					end

					format.json { render :show, status: :ok, location: @assignment }
				else
					log_assignment_errors
					raise ActiveRecord::Rollback
				end
			end

			unless @assignment.persisted? && @assignment.errors.empty?
				prepare_form(:edit)

				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @assignment.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /assignments/1
	# DELETE /assignments/1.json
	def terminate
		authorize @assignment

		if @assignment.terminate!
			redirect_to helpers.assignment_return_path(@assignment),
									notice: Assignment.msg(:terminated)
		else
			redirect_back fallback_location: helpers.assignment_return_path(@assignment),
										alert: Assignment.msg(:cannot_terminate)
		end
	end

	private

		def prepare_index_title
			if @kind
				title = Catalog::AssignmentKinds.val(@kind, :plural)
				concept = @kind
			else
				title = Assignment.label(:plural)
				concept = :person
			end
			title = helpers.person_title(title:, icon: { concept:, options: { namespace: "common", size: "50x50" } })
			title << helpers.participation_search_bar(Assignment, search_url: helpers.participation_index_path(kind: @kind))
		end

		# Prepare a assignment form
		def prepare_form(action)
			status_edit = action == :edit && to_boolean(params[:status])

			if status_edit
				a_fields = helpers.participation_status_form_fields(@assignment)
			else
				@title    = create_fields(helpers.assignment_form_title(@assignment, action))
				a_fields  = helpers.assignment_form_fields(@assignment)
				@p_fields = create_fields(helpers.person_form_fields(@assignment.person))
				@contacts = create_fields(helpers.person_relationships_form(@assignment.person))
			end

			@a_fields = create_fields(a_fields)
			@submit   = create_submit
		end

		def log_assignment_errors
			Rails.logger.debug @assignment.errors.full_messages
			Rails.logger.debug @assignment.person.errors.full_messages

			@assignment.person.relationships.each do |r|
				Rails.logger.debug r.errors.full_messages
				Rails.logger.debug r.related_person.errors.full_messages if r.related_person
			end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_assignment
			@assignment = Assignment.find(params[:id])

			@kind = @assignment.kind

			@club = @assignment.club
			raise ActiveRecord::RecordNotFound if params[:club_id]   && @club.id != params[:club_id].to_i

			@team = @assignment.team
			raise ActiveRecord::RecordNotFound if params[:team_id]   && @team&.id != params[:team_id].to_i

			@member = @assignment.membership
			raise ActiveRecord::RecordNotFound if params[:member_id] && @member.id != params[:member_id]
		end

		def load_assignment_kind
			@kind ||= Catalog::AssignmentKinds.normalize(params[:kind])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def assignment_params
			params.require(:assignment).permit(
				:membership_id,
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
