# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
class CoachesController < ApplicationController
	include Filterable
	before_action :set_coach, only: [:show, :edit, :update, :destroy]

	# GET /clubs/x/coaches 
	# GET /clubs/x/coaches.json
	def index
		if user_in_club? && check_access(roles: [:manager, :secretary])
			search   = params[:search].presence || session.dig('coach_filters','search')
			@coaches = Coach.search(search, current_user)
			respond_to do |format|
				format.xlsx do
					a_desc = "#{I18n.t("coach.export")} 'coaches.xlsx'"
					register_action(:exported, a_desc)
					response.headers['Content-Disposition'] = "attachment; filename=coaches.xlsx"
				end
				format.html do
					page   = paginate(@coaches)	# paginate results
					title  = helpers.person_title_fields(title: I18n.t("coach.many"), icon: "coach.svg")
					title << [{kind: "search-text", key: :search, value: search, url: club_coaches_path(@clubid)}]
					grid   = helpers.coach_grid(coaches: page)
					submit = {kind: "export", url: club_coaches_path(@clubid, format: :xlsx), working: false} if u_manager? || u_secretary?
					create_index(title:, grid:, page:, retlnk: club_path(@clubid), submit:)
					render :index
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/1
	# GET /coaches/1.json
	def show
		if @coach && (check_access(obj: @coach) || check_access(roles: [:manager, :secretary], obj: @coach.club, both: true))
			@fields = create_fields(helpers.coach_show_fields)
			@grid   = create_grid(helpers.team_grid(teams: @coach.team_list))
			retlnk  = get_retlnk
			submit  = edit_coach_path(@coach, club_id: @clubid, team_id: p_teamid, user: p_userid, rdx: @rdx) if (u_manager? || u_secretary? || u_coachid == @coach.id)
			@submit = create_submit(close: "back", retlnk:, submit:, frame: "modal")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/new
	def new
		if user_in_club? && check_access(roles: [:manager, :secretary])
			@coach = Coach.new(club_id: @clubid)
			@coach.build_person
			prepare_form(title: I18n.t("coach.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/1/edit
	def edit
		if @coach && (check_access(obj: @coach) || check_access(roles: [:manager, :secretary], obj: @coach.club, both: true))
			prepare_form(title: I18n.t("coach.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /coaches 
	# POST /coaches.json
	def create
		if user_in_club? && check_access(roles: [:manager, :secretary])
			respond_to do |format|
				@coach = Coach.new(club_id: @clubid)
				@coach.rebuild(coach_params)	# rebuild coach
				if @coach.id == nil then	# it's a new coach
					if @coach.paranoid_create # coach saved to database
						@coach.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("coach.created")} '#{@coach.s_name}'"
						register_action(:created, a_desc, url: coach_path(@coach, rdx: 2))
						format.html { redirect_to coach_path(@coach, rdx: 0), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :created, location: coach_path(@coach, rdx: 0) }
					else
						prepare_form(title: I18n.t("coach.new"))
						format.html { render :new }
						format.json { render json: @coach.errors, status: :unprocessable_entity }
					end
				else	# duplicate coach
					format.html { redirect_to coach_path(@coach, rdx: 0), notice: helpers.flash_message("#{I18n.t("coach.duplicate")} '#{@coach.s_name}'"), data: {turbo_action: "replace"}}
					format.json { render :show,  :created, location: coach_path(@coach) }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /coaches/1
	# PATCH/PUT /coaches/1.json
	def update
		if @coach && (check_access(obj: @coach) || check_access(roles: [:manager, :secretary], obj: Club.find(@clubid), both: true))
			r_path = coach_path(@coach, rdx: @rdx)
			respond_to do |format|
				@coach.rebuild(coach_params)
				if @coach.modified?	# coach has been edited
					if @coach.save
						@coach.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("coach.updated")} '#{@coach.s_name}'"
						register_action(:updated, a_desc, url: coach_path(@coach, rdx: 2))
						format.html { redirect_to r_path, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :ok, location: r_path }
					else
						prepare_form(title: I18n.t("coach.edit"))
						format.html { render :edit }
						format.json { render json: @coach.errors, status: :unprocessable_entity }
					end
				else	# no changes made
					format.html { redirect_to r_path, notice: no_data_notice, data: {turbo_action: "replace"}}
					format.json { render :show, status: :ok, location: r_path }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/import
	# GET /coaches/import.json
	def import
		if check_access(roles: [:manager, :secretary], obj: Club.find(@clubid), both: true)
			Coach.import(params[:file], u_clubid)	# added to import excel
			a_desc = "#{I18n.t("coach.import")} '#{params[:file].original_filename}'"
			register_action(:imported, a_desc, url: coaches_path(rdx: 2))
			redirect_to coaches_path(rdx: @rdx), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"}
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

 	# DELETE /coaches/1
	# DELETE /coaches/1.json
	def destroy
		# cannot destroy placeholder coach (id ==0)
		if @coach && (@coach.id != 0 && check_access(roles: [:admin]))
			c_name = @coach.s_name
			@coach.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("coach.deleted")} '#{c_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to coaches_path(rdx: @rdx), status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# defines correct retlnk based on params received
		def get_retlnk
			return team_path(id: p_teamid, user: current_user, rdx: @rdx) if p_teamid && current_user
			case @rdx&.to_i
			when 0, nil;	return (@clubid ? club_coaches_path(@clubid, rdx: 0) : u_path)
			when 1; return u_path
			when 2; return home_log_path
			else; return "/"
			end
		end

		# prepare form FieldComponents
		def prepare_form(title:)
			@title    = create_fields(helpers.person_form_title(@coach.person, title:, icon: @coach.picture))
			@c_fields = create_fields(helpers.coach_form_fields(team_id: p_teamid, user: p_userid))
			@p_fields = create_fields(helpers.person_form_fields(@coach.person))
			@submit   = create_submit
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_coach
			@coach  = Coach.find_by_id(params[:id]) unless @coach&.id==params[:id]&.to_i
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def coach_params
			params.require(:coach).permit(
				:id,
				:avatar,
				:club_id,
				:rdx,
				:team_id, # used to build return links
				:user,
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
