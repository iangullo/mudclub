# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
	before_action :set_drill, only: [:show, :edit, :update, :destroy, :versions]
	before_action :set_paper_trail_whodunnit

	# GET /drills or /drills.json
	def index
		if check_access(roles: [:manager, :coach])
			title   = helpers.drill_title_fields(title: I18n.t("drill.many"))
			title  << helpers.drill_search_bar(search_in: drills_path)
			@drills = filter!(Drill)	# Apply filters
			page = paginate(@drills)	# paginate results
			grid = helpers.drill_grid(drills: page)
			create_index(title:, grid:, page:, retlnk: "/")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/1 or /drills/1.json
	def show
		if check_access(roles: [:manager, :coach])
			@title   = create_fields(helpers.drill_show_title(title: I18n.t("drill.single")))
			@intro   = create_fields(helpers.drill_show_intro)
			@explain = create_fields(helpers.drill_show_explain)
			@tail    = create_fields(helpers.drill_show_tail)
			@submit  = create_submit(close: "back", retlnk: drills_path, submit: (u_manager? or (@drill.coach_id==u_coachid)) ? edit_drill_path(@drill) : nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/new
	def new
		if check_access(roles: [:manager, :coach])
			@drill = Drill.new
			prepare_form(title: I18n.t("drill.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/1/edit
	def edit
		if check_access(roles: [:admin], obj: @drill)
			prepare_form(title: I18n.t("drill.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /drills or /drills.json
	def create
		if check_access(roles: [:manager, :coach])
			respond_to do |format|
				@drill = Drill.new
				@drill.rebuild(drill_params)	# rebuild drill
				if @drill.save
					a_desc = "#{I18n.t("drill.created")} '#{@drill.name}'"
					register_action(:created, a_desc, url: drill_path(@drill, rdx: 2))
					format.html { redirect_to drill_path(@drill), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: @drill }
				else
					prepare_form(title: I18n.t("drill.new"))
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
		if check_access(roles: [:admin], obj: @drill)
			respond_to do |format|
				@drill.rebuild(drill_params)	# rebuild drill
				if @drill.modified?
					if @drill.save
						a_desc = "#{I18n.t("drill.updated")} '#{@drill.name}'"
						register_action(:updated, a_desc, url: drill_path(@drill, rdx: 2))
						format.html { redirect_to drill_path(@drill), status: :see_other, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :ok, location: @drill }
					else
						prepare_form(title: I18n.t("drill.edit"))
						format.html { render :edit, status: :unprocessable_entity }
						format.json { render json: @drill.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to drill_path, notice: no_data_notice, data: {turbo_action: "replace"}}
					format.json { render :show, status: :ok, location: drill_path }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /drills/1 or /drills/1.json
	def destroy
		if check_access(roles: [:admin], obj: @drill)
			d_name = @drill.name
			@drill.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("drill.deleted")} '#{d_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to drills_path, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/1/versions
	def versions
		if check_access(roles: [:manager, :coach])
			@title   = create_fields(helpers.drill_versions_title)
			@table   = create_fields(helpers.drill_versions_table)
			@submit  = create_submit(submit: nil)
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
			@skills   = Skill.list
			s_size    = 10
			@skills.each { |skill| s_size = skill.length if skill.length > s_size }
			@s_size   = s_size - 3
			@submit   = create_submit(retlnk: :back)
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_drill
			@drill = Drill.includes(:skills,:targets).with_rich_text_explanation.find_by_id(params[:id]) unless @drill&.id==params[:id]
		end

		# Only allow a list of trusted parameters through.
		def drill_params
			params.require(:drill).permit(
				:name,
				:material,
				:description,
				:coach_id,
				:explanation,
				:playbook,
				:kind_id,
				:skill_id,
				skills: [],
				target_ids: [],
				skill_ids: [],
				skills_attributes: [:id, :concept, :_destroy],
				drill_targets_attributes: [
					:id,
					:priority,
					:drill_id,
					:target_id,
					:_destroy,
					target_attributes: [:id, :aspect, :focus, :concept]
				]
			)
		end
end
