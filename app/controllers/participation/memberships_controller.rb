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
	before_action :set_member, only: [ :show, :edit, :update, :terminate ]
	before_action :load_membership_kind
	before_action :load_participation_context

	# GET /clubs/x/memberships
	# GET /clubs/x/memberships.json
	def index
		@policy = check_policy!(MembershipPolicy, kind: @kind, club: @club)

		history = (@search || @status) &&  @policy.history?
		@members =
			Membership.search(
				club: @club,
				kind: @kind,
				status: @status,
				search: @search,
				history:
			)

		title  = prepare_index_title
		page   = paginate(@members, 1.2)	# paginate results
		table  = helpers.memberships_table(members: page)
		retlnk = path_for(@club)
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /members/x
	# GET /members/x.json
	def show
		@policy    = check_policy!(MembershipPolicy, record: @member)
		@kind    ||= @member.kind.to_sym
		status_url = edit_path_for(@member, status: true) if @policy.edit?
		@title = create_fields(
			helpers.participation_title(
				@member,
				status_url:,
				just_icon: false
			)
		)

		@fields = create_fields(helpers.membership_show_fields(@member))
		@roles  = @member.assignments.order(starts_on: :desc)
		@page   = paginate(@roles, 1.2)	# paginate results
		@table  = create_table(helpers.assignment_history_table(@kind, @page))
		submit  = edit_path_for(@member) if @policy.update?
		@submit = create_submit(close: :back, retlnk: return_path_for(@member, search: @search), submit:)
	end

	# GET /members/new
	def new
		@policy = check_policy!(MembershipPolicy, club: @club, kind: @kind)
		@member = Membership.new(club: @club, kind: @kind)
		@member.build_person
		prepare_form(:create)
	end

	# POST /memberships
	# POST /memberships.json
	def create
		@policy = check_policy!(MembershipPolicy, club: @club, kind: @kind)
		respond_to do |format|
			Membership.transaction do
				@member = Membership.new(club: @club, kind: @kind)
				@member.rebuild(membership_params)
				@member.starts_on = Date.current

				if @member.save
					format.html do
						redirect_to post_save_path, notice: Membership.msg(:created)
					end

					format.json { render :show, status: :ok, location: post_save_path }
				else
					log_membership_errors
					raise ActiveRecord::Rollback
				end
			end

			unless @member.persisted? && @member.errors.empty?
				prepare_form(:create)

				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @member.errors, status: :unprocessable_entity }
			end
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

		respond_to do |format|
			Membership.transaction do
				@member.rebuild(membership_params)

				notice = Membership.msg(@member.modified? ? :updated : :no_change)
				if @member.save
					format.html do
						redirect_to path_for(@member), notice:
					end

					format.json { render :show, status: :ok, location: @member }
				else
					log_membership_errors
					raise ActiveRecord::Rollback
				end
			end

			unless @member.persisted? && @member.errors.empty?
				prepare_form(:edit)

				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @member.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /members/1
	# DELETE /members/1.json
	def terminate
		authorize @member

		if @member.terminate!
			redirect_to post_save_path,
									notice: Membership.msg(:terminated)
		else
			redirect_back fallback_location: post_save_path,
										alert: Membership.msg(:cannot_terminate)
		end
	end

	private
		# wrapper to set return link for CRUD operations
		def post_save_path
			return club_members_path(kind: @member.kind, search: params[:search].presence, status: params[:status].presence, rdx: @rdx) if @member
			(@club ? club_members_path(@club, kind: @kind, status: params[:status].presence, rdx: @rdx) : u_path)
		end

		def prepare_index_title
			if @kind
				title = Membership.kind_label(@kind, :plural)
				concept = @kind
			else
				title = Membership.label(:plural)
				concept = :person
			end
			title = helpers.person_title(title:, icon: { concept:, options: { namespace: "common", size: "50x50" } })
			title << helpers.participation_search_bar(Membership, search_url: club_members_path(@club))
		end

		# Prepare a member form
		def prepare_form(action)
			status_edit = action == :edit && to_boolean(params[:status])

			if status_edit
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

		def log_membership_errors
			Rails.logger.debug @member.errors.full_messages

			Rails.logger.debug @member.person.errors.full_messages

			@member.person.relationships.each do |r|
				Rails.logger.debug r.errors.full_messages
				Rails.logger.debug r.related_person.errors.full_messages if r.related_person
			end
		end

		def set_member
			@member = Membership.find(params[:id])
			@club   = @member&.club
			assert_param_matches!(:club_id, @club)

			@kind ||= @member.kind
		end

		def load_membership_kind
			@status ||= params[:status].presence
			return true if @kind
			p_kind = (params[:kind].presence || membership_params[:kind].presence)
								&.singularize&.to_sym
			@kind  = Membership.kind_catalog.normalize(p_kind)
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def membership_params
			@membership_params ||= params.require(:membership).permit(
				:person_id, :avatar, :joined_on, :left_on, :kind, :status, :notes, :rdx,
				person: [
					:id, :avatar, :name, :nick, :surname,
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
