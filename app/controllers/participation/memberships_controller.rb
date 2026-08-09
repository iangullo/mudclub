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
	include Filterable
	before_action :load_participation_context
	before_action :load_membership_kind
	before_action :set_member, only: [ :show, :edit, :update, :terminate ]

	# GET /clubs/x/memberships
	# GET /clubs/x/memberships.json
	def index
		@membership_policy = check_policy!(
			MembershipPolicy,
			kind: @kind,
			club: @club
		)

		search  = params[:search].presence
		history = search &&  @membership_policy.history?
		@members =
			Membership.search(
				club: @club,
				kind: @kind,
				search:,
				history:
			)

		title  = prepare_index_title
		page   = paginate(@members)	# paginate results
		table  = helpers.memberships_table(members: page)
		retlnk = base_lnk(club_path(@club, rdx: @rdx))
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /members/1
	# GET /members/1.json
	def show
		@membership_policy = check_policy!(MembershipPolicy, record: @member)
		status = @membership_policy.edit?

		@title = create_fields(
			helpers.participation_title(
				@member,
				status_url: edit_club_member_path(@member, status:),
				just_icon: false
			)
		)
		@fields = create_fields(helpers.membership_show_fields(@member))
		@table  = create_table(helpers.assignments_table(@member.assignments))
		submit  = edit_club_member_path(@member, rdx: @rdx) if @membership_policy.update?
		@submit = create_submit(close: :back, retlnk: post_save_path, submit:, frame: "modal")
	end

	# GET /members/new
	def new
		@membership_policy = check_policy!(MembershipPolicy, club: @club, kind: @kind)
		prepare_form(:new)
	end

	# POST /memberships
	# POST /memberships.json
	def create
		@membership_policy = check_policy!(MembershipPolicy, club: @club, kind: @kind)
		respond_to do |format|
			Membership.transaction do
				@member = Membership.new(club: @club, kind: @kind)
				@member.rebuild(membership_params)

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
				prepare_form(:new)

				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @member.errors, status: :unprocessable_entity }
			end
		end
	end

	# GET /members/1/edit
	def edit
		@membership_policy = check_policy!(MembershipPolicy, record: @member)
		prepare_form(:edit)
	end

	# PATCH/PUT /members/1
	# PATCH/PUT /members/1.json
	def update
		@membership_policy = check_policy!(MembershipPolicy, record: @member)

		respond_to do |format|
			Membership.transaction do
				@member.rebuild(membership_params)

				notice = Membership.msg(@member.modified? ? :updated : :no_change)
				if @member.save
					format.html do
						redirect_to club_member_path(@club, @member, rdx: @rdx), notice:
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
			return club_members_path(kind: @member.kind, search: @member.s_name, rdx: @rdx) if @member
			(@club ? club_members_path(@club, kind: @kind, rdx: @rdx) : u_path)
		end

		def prepare_index_title
			if @kind
				title = Catalog::MembershipKinds.val(@kind, :plural)
				concept = @kind
			else
				title = Membership.label(:plural)
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
					url: club_members_path(@club, kind: @kind, rdx: @rdx),
					fields:
				}
			]
		end

		# Prepare a member form
		def prepare_form(action)
			status_edit = action == :edit && params[:status].present?

			if status_edit
				m_fields = helpers.participation_status_form_fields(@member)
			else
				@title    = create_fields(helpers.membership_form_title(@member, action))
				m_fields  = helpers.membership_form_fields(@member)
				@p_fields = create_fields(helpers.person_form(@member.person))
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

		# Use callbacks to share common setup or constraints between actions.
		def set_member
			@member = Membership.find_by_id(params[:id]) unless @member&.id==params[:id]
			@club   = @member&.club
			@kind   = @member&.kind
		end

		def load_membership_kind
			@kind = Catalog::MembershipKinds.normalize(params[:kind])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def membership_params
			params.require(:membership).permit(
				:person_id,
				:joined_on,
				:left_on,
				:kind,
				:status,
				:notes,
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
					:surname,

					relationships_attributes: [
						:id,
						:kind,
						:_destroy,

						related_person_attributes: [
							:id,
							:name,
							:surname,
							:phone,
							:email,
							:birthday,
							:dni,
							:female,
							:address
						]
					]
				]
			)
		end
end
