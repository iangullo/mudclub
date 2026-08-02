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
	before_action :set_member, only: [ :show, :edit, :update, :terminate ]

	# GET /clubs/x/memberships
	# GET /clubs/x/memberships.json
	def index
		get_context
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
		table  = helpers.members_table(members: page)
		retlnk = base_lnk(club_path(@clubid, rdx: @rdx))
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /memberships/1
	# GET /memberships/1.json
	def show
		@membership_policy = check_policy!(MembershipPolicy, record: @member)
		@title  = create_fields(helpers.person_show_title(@member, title: Catalog::MembershipKinds.val(@member.kind)))
		@fields = create_fields(helpers.member_show_fields(@member))
		submit  = edit_club_member_path(@member, rdx: @rdx) if @membership_policy.update?
		@submit = create_submit(close: :close, submit:, frame: "modal")
	end

	# GET /memberships/new
	def new
		@membership_policy = check_policy!(MembershipPolicy, club: @club, kind: @kind)
	end

	# POST /memberships
	# POST /memberships.json
	def create
		@membership_policy = check_policy!(MembershipPolicy, club: @club, kind: @kind)
	end

	# GET /memberships/1/edit
	def edit
		@membership_policy = check_policy!(MembershipPolicy, record: @member)
	end

	# PATCH/PUT /memberships/1
	# PATCH/PUT /memberships/1.json
	def update
		@membership_policy = check_policy!(MembershipPolicy, record: @member)
	end

	# DELETE /memberships/1
	# DELETE /memberships/1.json
	def terminate
		@membership_policy = check_policy!(MembershipPolicy, record: @member)
	end

	private
		# wrapper to set return link for CRUD operations
		def crud_return
			return club_members_path(kind: @member.kind, search: @member.s_name, rdx: @rdx) if @member
			(@clubid ? club_members_path(@clubid, kind: @kind, rdx: @rdx) : u_path)
		end

		# prepare member action context
		def get_member_context
			@clubid = @member&.club_id
			@kind = @member&.kind
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
					url: club_members_path(@clubid, kind: @kind, rdx: @rdx),
					fields:
				}
			]
		end

		# Prepare a member form
		def prepare_form(action)
			@title    = create_fields(helpers.person_form_title(@member.person, icon: @member.picture, title: Membership.t_path(:action, action.to_sym), sex: true))
			@m_fields = create_fields(helpers.membership_form) # pending creation
			@p_fields = create_fields(helpers.person_form(@member.person))	# existing in helpers/people_helper
			@parents  = create_fields(helpers.player_form_parents) if @member.person.age < 18 # pending review
			@submit   = create_submit
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_member
			@member = Membership.find_by_id(params[:id]) unless @member&.id==params[:id]
			get_member_context
		end

		def get_context
			@club = Club.find(params[:club_id].presence) if params[:club_id].present?
			@kind = Catalog::MembershipKinds.normalize(params[:kind])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def membership_params
			params.require(:member).permit(
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
