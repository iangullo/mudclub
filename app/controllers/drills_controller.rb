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
class DrillsController < ApplicationController
	include Filterable
	before_action :set_drill, only: [:show, :edit, :update, :destroy]
	#skip_before_action :verify_authenticity_token, :only => [:create, :new, :edit, :update, :check_reload]

	# GET /drills or /drills.json
	def index
		if check_access(roles: [:admin, :coach])
			# Simple search by name/description for now
			@title  = create_fields(helpers.drill_title_fields(title: I18n.t("drill.many")))
			#@title << [{kind: "subtitle", value: I18n.t("catalog")}]
			@search = create_fields(helpers.drill_search_bar(search_in: drills_path))
			@drills = filter!(Drill)
			@grid   = create_grid(helpers.drill_grid(drills: @drills))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/1 or /drills/1.json
	def show
		if check_access(roles: [:admin, :coach], obj: @drill)
			@title   = create_fields(helpers.drill_show_title(title: I18n.t("drill.single")))
			@intro   = create_fields(helpers.drill_show_intro)
			@explain = create_fields(helpers.drill_show_explain)
			@tail    = create_fields(helpers.drill_show_tail)
			@submit  = create_submit(close: "back", close_return: drills_path, submit: (u_admin? or (@drill.coach_id==u_coachid)) ? edit_drill_path(@drill) : nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/new
	def new
		if check_access(roles: [:admin, :coach])
			@drill = Drill.new
			prepare_form(title: I18n.t("drill.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/1/edit
	def edit
		if check_access(roles: [:admin, :coach], obj: @drill)
			prepare_form(title: I18n.t("drill.edit"))
		else
			redirect_to drills_path, data: {turbo_action: "replace"}
		end
	end

	# POST /drills or /drills.json
	def create
		if check_access(roles: [:admin, :coach])
			respond_to do |format|
				@drill = Drill.new
				@drill.rebuild(drill_params)	# rebuild drill
				if @drill.save
					format.html { redirect_to drills_url, notice: helpers.flash_message("#{I18n.t("drill.created")} '#{@drill.name}'", "success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: @drill }
				else
					format.html { render :new }
					format.json { render json: @drill.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /drills/1 or /drills/1.json
	def update
		if check_access(roles: [:admin, :coach], obj: @drill)
			respond_to do |format|
				@drill.rebuild(drill_params)	# rebuild drill
				if @drill.save
					format.html { redirect_to drill_path, status: :see_other, notice: helpers.flash_message("#{I18n.t("drill.updated")} '#{@drill.name}'", "success"), data: {turbo_action: "replace"} }
					format.json { render :show, status: :ok, location: @drill }
				else
					format.html { render :edit, status: :unprocessable_entity }
					format.json { render json: @drill.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to drills_path, data: {turbo_action: "replace"}
		end
	end

	# DELETE /drills/1 or /drills/1.json
	def destroy
		if check_access(roles: [:admin, :coach], obj: @drill)
			d_name = @drill.name
			@drill.drill_targets.each { |d_t| d_t.delete }
			@drill.destroy
			respond_to do |format|
				format.html { redirect_to drills_url, notice: helpers.flash_message("#{I18n.t("drill.deleted")} '#{d_name}'"), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# prepare a drill form calling helpers to get the right FieldComponents
		def prepare_form(title:)
			@title    = create_fields(helpers.drill_form_title(title:))
			@playbook = create_fields(helpers.drill_form_playbook(playbook: @drill.playbook))
			@formdata = create_fields(helpers.drill_form_data)
			@explain  = create_fields(helpers.drill_form_explain)
			@formtail = create_fields(helpers.drill_form_tail)
			@submit   = create_submit(close_return: :back)
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_drill
			@drill = Drill.find_by_id(params[:id]) unless @drill.try(:id)==params[:id]
		end

		# Only allow a list of trusted parameters through.
		def drill_params
			params.require(:drill).permit(:name, :material, :description, :coach_id, :explanation, :playbook, :kind_id, :skill_id, skills: [], drill_steps: [], target_ids: [], skill_ids: [], skills_attributes: [:id, :concept, :_destroy], drill_targets_attributes: [:id, :priority, :drill_id, :target_id, :_destroy, target_attributes: [:id, :aspect, :focus, :concept]])
		end
end
