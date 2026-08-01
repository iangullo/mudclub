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
	before_action :set_member, only: [ :show, :edit, :update, :terminate, :destroy ]

	# GET /clubs/x/memberships
	# GET /clubs/x/memberships.json
	def index
	end

	# GET /memberships/1
	# GET /memberships/1.json
	def show
	end

	# GET /memberships/new
	def new
	end

	# GET /memberships/1/edit
	def edit
	end

	# POST /memberships
	# POST /memberships.json
	def create
	end

	# PATCH/PUT /memberships/1
	# PATCH/PUT /memberships/1.json
	def update
	end

	# DELETE /memberships/1
	# DELETE /memberships/1.json
	def terminate
	end

	# DELETE /memberships/1
	# DELETE /memberships/1.json
	def destroy
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
			@member = Player.find_by_id(params[:id]) unless @member&.id==params[:id]
			get_member_context
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def membership_params
			params.require(:member).permit(
				:id,
				:avatar,
				:club_id,
				:person_id,
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
