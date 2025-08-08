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
# Managament of drills/plays sotredin the server
class DrillsController < ApplicationController
	include Filterable
	include PdfGenerator
	before_action :set_drill, only: [:show, :edit, :update, :destroy, :versions]
	before_action :set_step, only: [:edit_diagram, :load_diagram, :update_diagram]
	before_action :set_paper_trail_whodunnit

	# GET /drills or /drills.json
	def index
		if check_access(roles: [:manager, :coach])
			title   = helpers.drill_title_fields(title: I18n.t("drill.many"))
			title  << helpers.drill_search_bar(search_in: drills_path)
			@drills = filter!(Drill)	# Apply filters
			page = paginate(@drills, 1.6)	# paginate results
			grid = helpers.drill_grid(drills: page)
			create_index(title:, grid:, page:, retlnk: base_lnk("/"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/1 or /drills/1.json
	def show
		if @drill && check_access(roles: [:manager, :coach])
			respond_to do |format|
				@intro = create_fields(helpers.drill_show_intro)
				@steps = create_fields(helpers.drill_show_steps)
				@tail  = create_fields(helpers.drill_show_tail)
				title  = helpers.drill_show_title(title: @drill.name)
				format.pdf do
					response.headers['Content-Disposition'] = "attachment; filename=drill.pdf"
					pdf = drill_to_pdf(title)
					send_data pdf.render(filename: "#{@drill.name}.pdf", type: "application/pdf")
				end
				format.html do
					@title = create_fields(title)
					submit   = edit_drill_path(@drill, rdx: @rdx) if (@drill.coach_id == u_coachid) || (u_manager? && u_clubid == @drill.coach.club_id)
					@submit  = create_submit(close: :back, retlnk: base_lnk(drills_path(rdx: @rdx)), submit:)
					render :show
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/new
	def new
		if check_access(roles: [:manager, :coach])
			@drill = Drill.new(sport_id: 1)  # will have to change this to pass from controller
			prepare_form("new")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/1/edit
	def edit
		if @drill && (check_access(obj: @drill) || club_manager?(@drill&.coach&.club))
			prepare_form("edit")
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
					retlnk = cru_return
					a_desc = "#{I18n.t("drill.created")} '#{@drill.name}'"
					register_action(:created, a_desc, url: drill_path(@drill, rdx: 2))
					format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: retlnk }
				else
					prepare_form("new")
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
		if @drill && (check_access(obj: @drill) || club_manager?(@drill&.coach&.club))
			respond_to do |format|
				retlnk = cru_return
				@drill.rebuild(drill_params)	# rebuild drill
				if @drill.modified?
					if @drill.save
						a_desc = "#{I18n.t("drill.updated")} '#{@drill.name}'"
						register_action(:updated, a_desc, url: drill_path(@drill, rdx: 2))
						format.html { redirect_to retlnk, status: :see_other, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :ok, location: retlnk }
					else
						prepare_form("edit")
						format.html { render :edit, status: :unprocessable_entity }
						format.json { render json: @drill.errors, status: :unprocessable_entity }
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

	# DELETE /drills/1 or /drills/1.json
	def destroy
		if @drill && check_access(roles: [:admin])
			d_name = @drill.name
			@drill.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("drill.deleted")} '#{d_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to drills_path(rdx: @rdx), notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/1/edit_diagram?step_id=X&order=Y
	def edit_diagram
		if @drill && (check_access(obj: @drill) || club_manager?(@drill&.coach&.club))
			if @step
				@title   = create_fields(helpers.drill_title_fields(title: @drill.name, subtitle: I18n.t("step.edit_diagram") + " ##{@step.order}"))
				@editor  = helpers.drill_form_diagram
				@submit  = create_submit(frame: "modal", retlnk: edit_drill_path(drill_id: @drill.id, rdx: @rdx), frame: "modal")
			else
				redirect_to edit_drill_path(@drill), data: {turbo_action: "replace"}
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /drills/1/edit_diagram?step_id=X&order=Y
	def load_diagram
		if @drill && (check_access(obj: @drill) || club_manager?(@drill&.coach&.club))
			if @step
				@title   = create_fields(helpers.drill_title_fields(title: @drill.name, subtitle: I18n.t("step.load_diagram") + " ##{@step.order}"))
				@loader  = create_fields(helpers.drill_form_diagram_file)
				@submit  = create_submit(retlnk: edit_drill_path(drill_id: @drill.id, rdx: @rdx), frame: "modal")
			else
				redirect_to edit_drill_path(@drill), data: {turbo_action: "replace"}
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH /drills/1/update_diagram?step_id=X
	# Recibe el SVG serializado y actualiza el paso
	def update_diagram
		if @drill && (check_access(obj: @drill) || club_manager?(@drill&.coach&.club))
			raw_data    = drill_params[:svgdata]&.strip
			parsed_data = raw_data.present? ? JSON.parse(raw_data) : nil
			if parsed_data && @step&.update(svgdata: parsed_data)
				respond_to do |format|
					format.html { redirect_to edit_drill_path(@drill), notice: I18n.t("step.diagram") + " ##{@step.order} " + I18n.t("status.saved") }
				end
			else
				redirect_to edit_diagram_drill_path(id: params[:id], notice: helpers.flash_message(I18n.t("status.no_data")), data: {turbo_action: "replace"}), status: :unprocessable_entity
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
		# wrapper to set return link for CRUD operations
		def cru_return
			drill_path(@drill, rdx: @rdx)
		end

		# pdf export of @drill content
		def drill_to_pdf(header)
			footer = "#{I18n.t('drill.author')}: #{@drill.coach.person.email}"
			pdf    = pdf_create(header:, footer:)
			pdf_label_text(label: I18n.t("drill.desc"), text: @drill.description) if @drill.description.present?
			pdf_label_text(label: I18n.t("target.many"), text: @drill.print_targets(array: false))
			pdf_separator_line
			pdf_rich_text(@drill.step_explanation) if @drill&.step_explanation&.present?
			pdf_separator_line
			pdf_label_text(label: I18n.t("skill.many"), text: @drill.print_skills)
			pdf
		end

		# prepare a drill form calling helpers to get the right FieldComponents
		def prepare_form(action)
			@title     = create_fields(helpers.drill_form_title(title: I18n.t("drill.#{action}")))
			@court     = @drill.court_mode
			@playbook  = create_fields(helpers.drill_form_playbook(playbook: @drill.playbook))
			@formdata  = create_fields(helpers.drill_form_data)
			@formsteps = create_fields(helpers.drill_form_steps)
			@formtail  = create_fields(helpers.drill_form_tail)
			@skills    = Skill.list
			s_size     = 10
			@skills.each { |skill| s_size = skill.length if skill.length > s_size }
			@s_size    = s_size - 3
			@submit    = create_submit(retlnk: (action == "new" ? drills_path(rdx: @rdx) : cru_return))
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_drill
			@drill = Drill.includes(:skills,:targets,:steps).find_by_id(params[:id]) unless @drill&.id==params[:id]
		end

		# retrieve or create a drill step from params received
		def set_step
			if (@drill = Drill.find_by_id(params[:id].presence&.to_i))
				if params[:step_id].present?
					@step = @drill.steps.find_by(id: params[:step_id])
				else	# Find using :order or build new step
					@step = @drill.steps.find_or_initialize_by(order: params[:order]&.to_i)
				end
				
				# Handle temporary SVG data
				@step.svgdata ||= JSON.parse(params[:svgdata]) if params[:svgdata].present?
				
				@court = @drill.court_mode
			end
		end

		# Only allow a list of trusted parameters through.
		def drill_params
			params.require(:drill).permit(
				:name,
				:material,
				:description,
				:coach_id,
				:court_mode,
				:svgdata,
				:step_explanation,
				:playbook,
				:kind_id,
				:rdx,
				:season_id,
				:skill_id,
				:step_id,
				skills: [],
				target_ids: [],
				skill_ids: [],
				skills_attributes: [:id, :concept, :_destroy],
				steps_attributes: [:id, :order, :diagram, :svgdata, :explanation, :_destroy],
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
