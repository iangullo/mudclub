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
	include PersonBearingController

	before_action :set_assignment, only: [ :show, :edit, :update, :terminate ]
	before_action :load_participation_context

	# GET /clubs/x/assignments
	# GET /clubs/x/assignments.json
	def index
		@policy = check_policy!(AssignmentPolicy, kind: @kind, club: @club, team: @team)

		assignments = Assignment.search(**search_options)

		@assignments = %i[board_member staff].include?(@kind) ?
			assignments.by_kind :
			assignments.by_age

		title  = prepare_index_title
		page   = paginate(@assignments, 1.7)
		table  = helpers.assignments_table(page)
		retlnk = helpers.assignments_base_path
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /assignments/1
	# GET /assignments/1.json
	def show
		@policy = check_policy!(AssignmentPolicy, record: @assignment)

		status_url = edit_path_for(@assignment, edit_status: true, kind: @kind, frame: :modal) if @policy.edit?

		fields =
			helpers.participation_title(
				@assignment,
				status_url:,
				just_icon: false
			) + helpers.assignment_show_fields

		@fields = create_fields(fields)
		submit  = edit_path_for(@assignment) if @policy.update?
		@submit = create_submit(submit:, frame: :modal)
	end

	# GET /assignments/new
	def new
		@policy     = check_policy!(AssignmentPolicy, club: @club, team: @team, kind: @kind)
		@assignment = Assignment.new(team: @team, kind: @kind)

		if @member
			@assignment.membership = @member
		else
			membership_kind = Array(Catalog::AssignmentKinds.membership_kind(@kind)).first || :athlete
			@assignment.build_membership(club: @club, kind: membership_kind, status: :active, joined_on: Date.current)
			@assignment.membership.build_person
		end
		prepare_form(:new)
	end

	# POST /assignments
	# POST /assignments.json
	def create
		@policy     = check_policy!(AssignmentPolicy, club: @club, team: @team, kind: @kind)
		@assignment = Assignment.new(team: @team, kind: @kind, membership: @member || build_blank_membership)

		save_with_person_merge(
			@assignment, assignment_params,
			on_success: ->(assignment, _) {
				@assignment = assignment
				respond_saved(
					location: helpers.assignment_return_path,
					notice: Assignment.msg(:created),
					template: :roster,
					turbo_status: :see_other
				)
			},
			on_failure: ->(assignment, result) {
				@assignment = assignment
				log_person_bearing_errors(@assignment)
				respond_to { |format| render_assignment_errors(:new, format, result) }
			}
		) do |assignment|
			reuse_existing_membership!(assignment) if @member.nil?
			assignment.starts_on ||= Date.current
			true
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
		retlnk  = helpers.assignment_return_path
		return handle_status_only_update(@assignment, redirect_url: retlnk) if status_only_update?(@assignment)

		save_with_person_merge(
			@assignment, assignment_params,
			on_success: ->(assignment, modified) {
				@assignment = assignment
				@member     = assignment.membership
				notice      = Assignment.msg(modified ? :updated : :no_change)
				respond_saved(location: retlnk, notice:)
			},
			on_failure: ->(assignment, result) {
				@assignment = assignment
				log_person_bearing_errors(@assignment)
				respond_to { |format| render_assignment_errors(:edit, format, result) }
			}
		)
	end

	# DELETE /assignments/1
	# DELETE /assignments/1.json
	def terminate
		authorize @assignment

		handle_terminate(@assignment, redirect_url: helpers.assignment_return_path)
	end

	private

		def build_blank_membership
			Membership.new(
				club:      @club,
				kind:      membership_kind(@kind || :athlete),
				status:    :active,
				joined_on: Date.current
			)
		end

		def membership_kind(kind)
			return kind if Membership.kind_catalog.include?(kind)
			return nil unless Assignment.kind_catalog.include?(kind)

			Assignment.kind_catalog.fetch(kind)[:membership]
		end

		def prepare_index_title
			if @kind
				title   = Assignment.kind_label(@kind, :plural)
				concept = @kind
			else
				title   = Assignment.label(:plural)
				concept = :person
			end
			title = helpers.person_title(title:, icon: { concept:, options: { namespace: "common", size: "50x50" } })
			title << helpers.participation_search_bar(Assignment, search_url: helpers.participation_index_path(kind: @kind))
		end

		def prepare_form(action)
			edit_status = action == :edit && to_boolean(params[:edit_status])

			if edit_status
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

		def reuse_existing_membership!(assignment)
			person = assignment.person
			return unless person&.persisted?

			kind     = assignment.membership.kind
			existing = person.memberships.for_club(@club).of_kind(kind).current.first
			assignment.membership = existing if existing
		end

		def render_assignment_errors(action, format, result = nil)
			render_form_errors(action, format, record: @assignment, result:, fallback_message: Assignment.val(:none))
		end

		def search_options
			search_opts = { club: @club, team: @team, status: @status, search: @search, history: @search && @policy.history? }
			if (@staff = get_param(:staff))
				kinds =
					if @team
						Assignment.team_staff_kinds
					elsif @club
						Assignment.club_staff_kinds
					else
						[]
					end
				search_opts[:assignment_kind] = kinds
			else
				search_opts[:membership_kind] = @kind
			end
			search_opts
		end

		def set_assignment
			if (@assignment = Assignment.includes(:membership, :team).find(params[:id]))
				@kind   = @assignment.kind
				@member = @assignment.membership
				assert_param_matches!(:member_id, @member)
				@club   = @assignment.club
				assert_param_matches!(:club_id, @club)
				@team   = @assignment.team
				assert_param_matches!(:team_id, @team)
			end
		end

		def assignment_params
			@assignment_params ||= params.require(:assignment).permit(
				:kind, :membership_id, :team_id, :starts_on, :ends_on, :number,
				:notes, :avatar, :person_merge, :status, :edit_status, :rdx,
				person_attributes: person_permitted_params
			)
		end
end
