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
	before_action :set_assignment, only: [ :show, :edit, :update, :terminate ]
	before_action :load_assignment_kind
	before_action :load_participation_context

	# GET /clubs/x/assignments
	# GET /clubs/x/assignments.json
	def index
		@policy = check_policy!(AssignmentPolicy, kind: @kind, club: @club, team: @team)

		history = @search &&  @policy.history?
		@assignments =
			Assignment.search(
				club: @club,
				membership_kind: @kind,
				search: @search,
				history:
			)

		title  = prepare_index_title
		page   = paginate(@assignments)	# paginate results
		table  = helpers.assignments_table(page)
		retlnk = helpers.assignments_base_path
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /assignments/1
	# GET /assignments/1.json
	def show
		@policy = check_policy!(AssignmentPolicy, record: @assignment)
		@status = @policy.edit?

		fields  =
			helpers.participation_title(
				@assignment,
				status_url: edit_path_for(@assignment, status:),
				just_icon: false
			) + helpers.assignment_show_fields

		@fields = create_fields(fields)
		submit  = edit_path_for(@assignment) if @policy.update?
		@submit = create_submit(submit:, frame: :modal)
	end

	# GET /assignments/new
	# TODO: Work on this - it will be quite different...
	def new
		@policy = check_policy!(AssignmentPolicy, club: @club, team: @team, kind: @kind)
		@assignment = Assignment.new(team: @team, kind: @kind)

		if @member
			@assignment.membership = @member
		else
			membership_kind = Array(Catalog::AssignmentKinds.membership_kind(@kind)).first || :athlete
			@assignment.build_membership(club: @club, kind: membership_kind, status: :active, joined_on: Date.current)
			@assignment.membership.build_person
		end
		prepare_form(:create)
	end

	# POST /assignments
	# POST /assignments.json
	# TODO: Work on this - it will be quite different...
	def create
		@policy = check_policy!(AssignmentPolicy, club: @club, team: @team, kind: @kind)

		respond_to do |format|
			@assignment = Assignment.new(team: @team, kind: @kind)
			membership  = @member || prepared_membership
			if membership
				Assignment.transaction do
					@assignment.membership = membership
					@assignment.rebuild(assignment_params)
					@assignment.starts_on ||= Date.current

					if @assignment.save
						format.html do
							redirect_to helpers.assignment_return_path, notice: Assignment.msg(:created)
						end

						format.json { render :show, status: :ok, location: helpers.assignment_return_path }
					else
						log_assignment_errors
						raise ActiveRecord::Rollback
					end
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
		@policy = check_policy!(AssignmentPolicy, record: @assignment)
		prepare_form(:edit)
	end

	# PATCH/PUT /assignments/1
	# PATCH/PUT /assignments/1.json
	def update
		@policy = check_policy!(AssignmentPolicy, record: @assignment)

		respond_to do |format|
			Assignment.transaction do
				@assignment.rebuild(assignment_params)

				notice = Assignment.msg(@assignment.modified? ? :updated : :no_change)
				if @assignment.save
					format.html do
						redirect_to helpers.assignment_return_path, notice:
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
			redirect_to helpers.assignment_return_path,
									notice: Assignment.msg(:terminated)
		else
			redirect_back fallback_location: helpers.assignment_return_path,
										alert: Assignment.msg(:cannot_terminate)
		end
	end

	private

		def prepare_index_title
			if @kind
				title = Assignment.kind_label(@kind, :plural)
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
				a_fields  = helpers.assignment_form_fields(@assignment)
				@kind_f   = create_fields(helpers.assignment_form_kind_fields(@assignment))
				@p_header = create_fields(helpers.assignment_form_title(@assignment, action))
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
			@assignment = Assignment.includes(:membership, :team).find(params[:id])

			@kind   = @assignment.kind
			@member = @assignment.membership
			assert_param_matches!(:member_id, @member)

			@club   = @assignment.club
			assert_param_matches!(:club_id, @club)

			@team   = @assignment.team
			assert_param_matches!(:team_id, @team)
		end

		def load_assignment_kind
			return true if @kind
			p_kind = (params[:kind].presence || assignment_params[:kind].presence)
								&.singularize&.to_sym
			@kind  = Assignment.kind_catalog.normalize(p_kind)
		end

		# Flow B: no pre-existing member. Resolve the person from params, then
		# reuse their current membership in this club if one exists.
		def prepared_membership
			person = resolve_person_for_create
			return nil unless person

			kind = @kind || :athlete

			person.memberships.for_club(@club).of_kind(kind).current.first ||
			person.memberships.build(
				club:      @club,
				kind:      kind,
				status:    :active,
				joined_on: Date.current
			)
		end

		def resolve_person_for_create
			attrs = assignment_params[:person_attributes]
			return Person.new if attrs.blank?

			result = Person.resolve(attrs)
			return nil if result[:status] == :ambiguous

			result[:person] || Person.new
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def assignment_params
			@assignment_params ||= params.require(:assignment).permit(
				:kind, :membership_id, :team_id, :starts_on, :ends_on,
				:number, :notes, :avatar, :status, :rdx,
				person_attributes: [
					:id, :name, :nick, :surname,
					:dni, :id_back, :id_front, :female,
					:birthday, :address, :email, :phone,

					relationships_attributes: [
						:id, :kind, :_destroy,
						related_person_attributes: [
							:id, :dni, :name, :surname, :email, :phone
						]
					]
				]
			)
		end
end
