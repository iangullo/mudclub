# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
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
	#skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_coach, only: [:show, :edit, :update, :destroy]

	# GET /coaches
	# GET /coaches.json
	def index
		if check_access(roles: [:manager, :coach])
			@coaches = get_coaches
			title    = helpers.person_title_fields(title: I18n.t("coach.many"), icon: "coach.svg")
			title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('coach_filters','search'), url: coaches_path}]
			@fields = create_fields(title)
			@grid   = create_grid(helpers.coach_grid)
			submit  = {kind: "export", url: teams_path(format: :xlsx), working: false} if u_manager?
			@submit = create_submit(close: "back", close_return: u_manager? ? "/" : user_path(current_user), submit:)
			respond_to do |format|
				format.xlsx {
					a_desc = "#{I18n.t("coach.export")} 'coaches.xlsx'"
					register_action(:exported, a_desc)
					response.headers['Content-Disposition'] = "attachment; filename=coaches.xlsx"
				}
				format.html { render :index }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/1
	# GET /coaches/1.json
	def show
		if check_access(roles: [:manager, :coach])
			@fields = create_fields(helpers.coach_show_fields)
			@grid   = create_grid(helpers.team_grid(teams: @coach.team_list))
			@submit = create_submit(submit: (u_manager? or u_coachid==@coach.id) ? edit_coach_path(@coach, retlnk: @retlnk) : nil, frame: "modal")
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/new
	def new
		if check_access(roles: [:manager])
			@coach = Coach.new(active: true)
			@coach.build_person
			prepare_form(title: I18n.t("coach.new"))
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/1/edit
	def edit
		if check_access(roles: [:manager], obj: @coach)
			prepare_form(title: I18n.t("coach.edit"))
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# POST /coaches
	# POST /coaches.json
	def create
		if check_access(roles: [:manager])
			respond_to do |format|
				@coach  = Coach.new
				@retlnk = get_retlnk || coaches_path
				@coach.rebuild(coach_params)	# rebuild coach
				if @coach.modified? then	# it's a new coach
					if @coach.paranoid_create # coach saved to database
						@coach.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("coach.created")} '#{@coach.s_name}'"
						register_action(:created, a_desc, url: coach_path(@coach, retlnk: home_log), modal: true)
						format.html { redirect_to coaches_path(search: @coach.s_name), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: coaches_path(search: @coach.s_name) }
					else
						prepare_form(title: I18n.t("coach.new"))
						format.html { render :new }
						format.json { render json: @coach.errors, status: :unprocessable_entity }
					end
				else	# duplicate coach
					format.html { redirect_to coaches_path(search: @coach.s_name), notice: helpers.flash_message("#{I18n.t("coach.duplicate")} '#{@coach.s_name}'"), data: {turbo_action: "replace"}}
					format.json { render :index,  :created, location: coaches_path(search: @coach.s_name) }
				end
			end
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /coaches/1
	# PATCH/PUT /coaches/1.json
	def update
		if check_access(roles: [:manager], obj: @coach)
			respond_to do |format|
				@coach.rebuild(coach_params)
				if @coach.modified?	# coach has been edited
					if @coach.save
						@coach.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("coach.updated")} '#{@coach.s_name}'"
						register_action(:updated, a_desc, url: coach_path(@coach, retlnk: home_log_path), modal: true)
						format.html { redirect_to coaches_path(search: @coach.s_name), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :ok, location: coaches_path(search: @coach.s_name) }
					else
						prepare_form(title: I18n.t("coach.edit"))
						format.html { render :edit }
						format.json { render json: @coach.errors, status: :unprocessable_entity }
					end
				else	# no changes made
					@retlnk = get_retlnk ||= "/"
					format.html { redirect_to @retlnk, notice: no_data_notice, data: {turbo_action: "replace"}}
					format.json { render :index, status: :ok, location: @retlnk }
				end
			end
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/import
	# GET /coaches/import.json
	def import
		if check_access(roles: [:manager])
			Coach.import(params[:file])	# added to import excel
			a_desc = "#{I18n.t("coach.import")} '#{params[:file].original_filename}'"
			register_action(:imported, a_desc, url: coaches_path(retlnk: home_log_path))
			redirect_to coaches_path, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"}
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

 	# DELETE /coaches/1
	# DELETE /coaches/1.json
	def destroy
		if check_access(roles: [:manager])
			c_name = @coach.s_name
			@coach.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("coach.deleted")} '#{c_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to coaches_path, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	private
		# get coach list depending on the search parameter & user role
		def get_coaches
			if params[:search].present?
				@coaches = Coach.search(params[:search])
			else
				if u_manager? or u_coach?
					Coach.active
				else
					Coach.none
				end
			end
		end

		# defines correct retlnk based on params received
		def get_retlnk
			if (rlnk = (param_passed(:retlnk) || param_passed(:coach, :retlnk)))
				return safelink(rlnk)
			elsif current_user
				return user_path(current_user)
			end
		end

		# prepare form FieldComponents
		def prepare_form(title:)
			@retlnk ||= coaches_path(search: @coach.s_name)	# ensure we have a valid return link
			@title    = create_fields(helpers.person_form_title(@coach.person, title:, icon: @coach.picture))
			@c_fields = create_fields(helpers.coach_form_fields)
			@p_fields = create_fields(helpers.person_form_fields(@coach.person))
			@submit   = create_submit
		end

		# return array of safe links to redirect
		def safelink(lnk=nil)
			val = [home_log_path, coaches_path]
			val << (u_path = current_user ? user_path(current_user) : "/")
			@coach&.teams.each do |team|
				val << team_path(retlnk: team_path(team, season_id: team.season.id))
			end
			validate_link(lnk, val)
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_coach
			@coach  = Coach.find_by_id(params[:id]) unless @coach&.id==params[:id]
			@retlnk = get_retlnk
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def coach_params
			params.require(:coach).permit(
				:id,
				:active,
				:avatar,
				:retlnk,
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
