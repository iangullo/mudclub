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
		if check_access(roles: [:admin, :coach])
			@coaches = get_coaches
			title    = helpers.coach_title(title: I18n.t("coach.many"))
			title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('coach_filters','search'), url: coaches_path}]
			@fields = create_fields(title)
			@grid   = create_grid(helpers.coach_grid)
			respond_to do |format|
				format.xlsx {
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
		if check_access(roles: [:admin, :coach], obj: @coach)
			@fields = create_fields(helpers.coach_show_fields)
			@grid   = create_grid(helpers.team_grid(teams: @coach.teams.order(:season_id)))
			@submit = create_submit(submit: (current_user.admin? or current_user.person.coach_id==@coach.id) ? edit_coach_path(@coach) : nil, frame: "modal")
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/new
	def new
		if check_access(roles: [:admin])
			@coach = Coach.new(active: true)
			@coach.build_person
			prepare_form(title: I18n.t("coach.new"))
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/1/edit
	def edit
		if check_access(roles: [:admin, :coach], obj: @coach)
			prepare_form(title: I18n.t("coach.edit"))
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# POST /coaches
	# POST /coaches.json
	def create
		if check_access(roles: [:admin])
			respond_to do |format|
				@coach = Coach.new
				@coach.rebuild(coach_params)	# rebuild coach
				if @coach.is_duplicate? then
					format.html { redirect_to coaches_path(search: @coach.s_name), notice: helpers.flash_message("#{I18n.t("coach.duplicate")} '#{@coach.s_name}'"), data: {turbo_action: "replace"}}
					format.json { render :index,  :created, location: coaches_path(search: @coach.s_name) }
				else
					@coach.person.save unless @coach.person.persisted?
					if @coach.save # coach saved to database
						if @coach.person.coach_id != @coach.id
							@coach.person.coach_id = @coach.id
							@coach.person.save
						end
						format.html { redirect_to coaches_path(search: @coach.s_name), notice: helpers.flash_message("#{I18n.t("coach.created")} '#{@coach.s_name}'", "success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: coaches_path(search: @coach.s_name) }
					else
						format.html { render :new }
						format.json { render json: @coach.errors, status: :unprocessable_entity }
					end
				end
			end
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /coaches/1
	# PATCH/PUT /coaches/1.json
	def update
		if check_access(roles: [:admin], obj: @coach)
			respond_to do |format|
				@coach.rebuild(coach_params)
				if @coach.save
					format.html { redirect_to coaches_path(search: @coach.s_name), notice: helpers.flash_message("#{I18n.t("coach.updated")} '#{@coach.s_name}'", "success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :ok, location: coaches_path(search: @coach.s_name) }
				else
					format.html { render :edit }
					format.json { render json: @coach.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	# GET /coaches/import
	# GET /coaches/import.json
	def import
		if check_access(roles: [:admin])
			Coach.import(params[:file])	# added to import excel
			format.html { redirect_to coaches_path, notice: helpers.flash_message("#{I18n.t("coach.import")} '#{params[:file].original_filename}'", "success"), data: {turbo_action: "replace"} }
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

 	# DELETE /coaches/1
	# DELETE /coaches/1.json
	def destroy
		if check_access(roles: [:admin], obj: @coach)
			c_name = @coach.s_name
			unlink_person
			@coach.destroy
			respond_to do |format|
				format.html { redirect_to coaches_path, status: :see_other, notice: helpers.flash_message("#{I18n.t("coach.deleted")} '#{c_name}'"), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to coaches_path, data: {turbo_action: "replace"}
		end
	end

	private
		# reload edit/create form if person exists without a coach record
		def reload_data(format)
			if @coach.person.coach_id==0
				format.html { render :new }
				format.json { render :new, status: :ok }
			end
		end

		# De-couple from associated person
		def unlink_person
			if @coach.person.try(:coach_id) == @coach.id
				p = @coach.person
				p.coach=Coach.find(0)	# map to empty coach
				p.save
				@coach.person_id = 0	# map to empty person
			end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_coach
			@coach = Coach.find_by_id(params[:id]) unless @coach.try(:id)==params[:id]
		end

		# get coach list depending on the search parameter & user role
		def get_coaches
			if (params[:search] != nil) and (params[:search].length > 0)
				@coaches = Coach.search(params[:search])
			else
				if current_user.admin? or current_user.is_coach?
					Coach.active
				else
					Coach.none
				end
			end
		end

		# prepare form FieldComponents
		def prepare_form(title:)
			@title    = create_fields(helpers.coach_form_title(title:, rows: 4, cols: 3))
			@c_fields = create_fields(helpers.coach_form_fields)
			@p_fields = create_fields(helpers.coach_person_fields)
			@submit   = create_submit
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def coach_params
			params.require(:coach).permit(:id, :active, :avatar, :retlnk, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :email, :phone])
		end
end
