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
# Handle Membership views - always linked to a club
class MembershipsController < ApplicationController
	include PersonBearingController

	before_action :set_member, only: [ :show, :edit, :update, :terminate, :anonymize ]
	before_action :load_participation_context

	# GET /clubs/x/memberships
	# GET /clubs/x/memberships.json
	def index
		@policy = check_policy!(MembershipPolicy, kind: @kind, club: @club)

		history = (@search || @status) && @policy.history?
		@members =
			Membership.search(
				club: @club,
				kind: @kind,
				status: @status,
				search: @search,
				history:
			).by_age

		title  = prepare_index_title
		page   = paginate(@members, 1.7)
		table  = helpers.memberships_table(members: page)
		retlnk = path_for(@club)
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /members/x
	# GET /members/x.json
	def show
		@policy = check_policy!(MembershipPolicy, record: @member)

		status_url = edit_path_for(@member, edit_status: true, kind: @kind, frame: :modal) if @policy.edit?

		@title  = create_fields(helpers.participation_title(@member, status_url:, just_icon: false))
		@fields = create_fields(helpers.membership_show_fields(@member))
		@roles  = @member.assignments.order(starts_on: :desc)
		@page   = paginate(@roles, 1.2)
		@table  = create_table(helpers.assignment_history_table(@kind, @page))
		submit  = edit_path_for(@member) if @policy.update?
		actions = []
		if @policy.anonymize? && @member.terminated?
			actions << {
				kind: :anonymize,
				url: anonymize_club_member_path(@club, @member),
				name: @member.s_name
			}
		end
		@submit = create_submit(close: :back, retlnk: index_path_for(@member, search: @search), submit:, actions:, frame: :modal)
	end

	# GET /members/new
	def new
		@policy = check_policy!(MembershipPolicy, club: @club, kind: @kind)

		@member = Membership.new(club: @club, kind: @kind)
		@member.build_person
		prepare_form(:new)
	end

	# POST /memberships
	# POST /memberships.json
	def create
		@policy = check_policy!(MembershipPolicy, club: @club, kind: @kind)

		@member = Membership.new(club: @club, kind: @kind)

		save_with_person_merge(
			@member, membership_params,
			on_success: ->(member, _) {
				@member = member
				respond_saved(location: post_save_path, notice: Membership.msg(:created))
			},
			on_failure: ->(member, result) {
				@member = member
				log_person_bearing_errors(@member)
				respond_to { |format| render_member_errors(:new, format, result) }
			}
		) do |member|
			member.starts_on = Date.current
			true
		end
	end

	# GET /members/1/edit
	def edit
		@policy = check_policy!(MembershipPolicy, record: @member)

		prepare_form(:edit)
	end

	# PATCH/PUT /members/1
	# PATCH/PUT /members/1.json
	def update
		@policy = check_policy!(MembershipPolicy, record: @member)

		return handle_status_only_update(@member, redirect_url: path_for(@member)) if status_only_update?(@member)

		save_with_person_merge(
			@member, membership_params,
			on_success: ->(member, modified) {
				@member = member
				notice  = Membership.msg(modified ? :updated : :no_change)
				respond_saved(location: path_for(@member), notice:)
			},
			on_failure: ->(member, result) {
				@member = member
				log_person_bearing_errors(@member)
				respond_to { |format| render_member_errors(:edit, format, result) }
			}
		)
	end

	# DELETE /members/1
	# DELETE /members/1.json
	def terminate
		@policy = check_policy!(MembershipPolicy, record: @member)

		handle_terminate(@member, redirect_url: post_save_path)
	end

	# GDPR compliance - anonymize data
	def anonymize
		@policy = check_policy!(MembershipPolicy, record: @member)

		handle_anonymize(
			@member,
			redirect_url: index_path_for(@member, search: @search),
			require_terminated: true
		)
	end

	private

		def post_save_path
			return path_for(@member, kind: @member.kind, search: params[:search].presence, status: params[:status].presence) if @member
			(@club ? club_members_path(@club, kind: @kind, status: params[:status].presence, rdx: @rdx) : u_path)
		end

		def prepare_index_title
			if @kind
				title   = Membership.kind_label(@kind, :plural)
				concept = @kind
			else
				title   = Membership.label(:plural)
				concept = :person
			end
			title = helpers.person_title(title:, icon: { concept:, options: { namespace: "common", size: "50x50" } })
			title << helpers.participation_search_bar(Membership, search_url: club_members_path(@club))
		end

		def prepare_form(action)
			edit_status = action == :edit && to_boolean(params[:edit_status])

			if edit_status
				m_fields = helpers.participation_status_form_fields(@member)
			else
				m_fields  = helpers.membership_form_fields(@member)
				@p_header = create_fields(helpers.membership_form_title(@member, action))
				@p_fields = create_fields(helpers.person_form_fields(@member.person))
				@contacts = create_fields(helpers.person_relationships_form(@member.person))
			end

			@m_fields = create_fields(m_fields)
			@submit   = create_submit
		end

		def render_member_errors(action, format, result = nil)
			render_form_errors(action, format, record: @member, result:, fallback_message: Membership.val(:none))
		end

		def set_member
			if (@member = Membership.find(params[:id]))
				@club = @member.club
				@kind = @member.kind
				assert_param_matches!(:club_id, @club)
			end
		end

		def membership_params
			@membership_params ||= params.require(:membership).permit(
				:person_id, :club_id, :joined_on, :left_on, :kind, :notes,
				:avatar, :person_merge, :status, :edit_status, :rdx,
				person_attributes: person_permitted_params
			)
		end
end
