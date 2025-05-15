# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
class ClubsController < ApplicationController
	before_action :set_club, only: [:show, :edit, :update, :destroy]

	# GET /clubs or /clubs.json
	def index
		if check_access(roles: [:admin, :manager])
			@clubs  = Club.search(params[:search], current_user)
			page    = paginate(@clubs)
			title   = I18n.t("club.#{u_manager? ? 'rivals': '.many'}")
			title   = helpers.club_title_fields(title:, icon: {concept: "rivals", size: "50x50"})
			title << [{kind: :search_text, key: :search, value: params[:search] || session.dig('club_filters', 'search'), url: clubs_path, size: 10}]
			grid    = helpers.club_grid(clubs: page)
			retlnk  = base_lnk(u_clubid ? club_path(u_clubid) : "/")
			create_index(title:, grid:, page:, retlnk:)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /clubs/1 or /clubs/1.json
	def show
		if @club && check_access(roles: [:admin, :manager, :secretary])
			@title  = create_fields(helpers.club_show_title)
			@links  = create_fields(helpers.club_links)
			if (user_in_club?)	# my own club: show events
				@grid   = create_fields(helpers.event_list_grid(obj: Season.latest))
			else	# off return to  the user's club
				close  = :back
				retlnk = base_lnk(clubs_path)
			end
			submit  = edit_club_path(@club, rdx: @rdx) if u_admin? || club_manager?(@club)
			@submit = create_submit(close:, retlnk:, submit:, frame: "modal")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /clubs/new
	def new
		if check_access(roles: [:admin])
			m_club  = u_club
			locale  = m_club&.locale || "en"
			country = m_club&.country || "US"
			@club   = Club.new(settings: {locale: , country:})
			prepare_form(title: I18n.t("club.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /clubs/1/edit
	def edit
		if @club && (u_admin? || club_manager?(@club))
			prepare_form(title: I18n.t("club.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /clubs or /clubs.json
	def create
		if check_access(roles: [:admin])
			respond_to do |format|
				@club = Club.fetch(club_params, create: true)
				@club.rebuild(club_params)
				if @club.id == nil then	# it's a new club
					if @club.save # club saved to database
						a_desc = "#{I18n.t("club.created")} '#{@club.nick}'"
						register_action(:created, a_desc, url: club_path(@club, rdx: 2))
						format.html { redirect_to club_path(@club, rdx: 0), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :created, location: club_path(@club, rdx: 0) }
					else
						prepare_form(title: I18n.t("club.new"))
						format.html { render :new, status: :unprocessable_entity }
						format.json { render json: @club.errors, status: :unprocessable_entity }
					end
				else	# duplicate club
					format.html { redirect_to club_path(@club, rdx: 0), notice: helpers.flash_message("#{I18n.t("club.duplicate")} '#{@club.nick}'"), data: {turbo_action: "replace"}}
					format.json { render :index, :created, location: club_path(@club, rdx: 0) }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /clubs/1 or /clubs/1.json
	def update
		if @club && (u_admin? || club_manager?(@club))
			respond_to do |format|
				retlnk = club_path(@club, rdx: @rdx)
				@club.rebuild(club_params)
				if @club.modified?# club has been edited
					if @club.save
						a_desc = "#{I18n.t("club.updated")} '#{@club.nick}'"
						register_action(:updated, a_desc, url: club_path(@club, rdx: 2))
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :ok, location: retlnk }
					else
						prepare_form(title: I18n.t("club.edit"))
						format.html { render :edit, status: :unprocessable_entity }
						format.json { render json: @club.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to retlnk, notice: no_data_notice, data: {turbo_action: "replace"}}
					format.json { render :show, status: :ok, location: retlnk }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /clubs/1 or /clubs/1.json
	def destroy
		# cannot destroy user's club
		if @club && (check_access(roles: [:admin]) && (@clubid != u_clubid))
			c_name = @club.name
			@club.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("club.deleted")} '#{c_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to clubs_path(rdx:0), status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# retrurn the correct retlnk based on role, rdx
		def get_retlnk
			case @rdx&.to_i
			when nil, 0; return club_path(u_clubid)
			when 1; return team_id ? team_path(team_id, rdx: @rdx) : u_path
			when 2; return home_log_path
			end
		end

		# prepare a form to edit/create a club
		def prepare_form(title:)
			@title  = create_fields(helpers.club_form_title(title:))
			@fields = create_fields(helpers.club_form_fields)
			@submit = create_submit
		end

		def set_club
			c_id    = get_param(:id, objid: true) || @clubid
			@club   = Club.find_by_id(c_id)
			@clubid = @club.id
		end

		# Only allow a list of trusted parameters through.
		def club_params
			params.require(:club).permit(
				:id,
				:address,
				:avatar,
				:country,
				:email,
				:locale,
				:name,
				:nick,
				:phone,
				:rdx,
				:website,
				social: [
					facebook: {},
					google: {},
					instagram: {},
					twitter: {},
				]
			)
		end
end
