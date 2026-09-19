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
# Managament of drills/plays sotredin the server
# TODO: ADAPT MODEL & CONTROLLER to 2.x membhership-driven domain
class DrillsController < ApplicationController
	include Filterable
	include PdfGenerator
	before_action :set_drill, only: [ :show, :edit, :update, :destroy, :versions ]
	before_action :set_step, only: [ :edit_diagram, :load_diagram, :update_diagram ]
	before_action :set_paper_trail_whodunnit

	# GET /drills or /drills.json
	def index
		@policy = check_policy!(DrillPolicy)

		title   = helpers.drill_title(title: I18n.t("drill.many"))
		title  << helpers.drill_search_bar(search_in: drills_path)
		@drills = filter!(Drill)	# Apply filters
		page  = paginate(@drills, 1.6)	# paginate results
		table = helpers.drill_table(drills: page)
		create_index(title:, table:, page:, retlnk: back_link)
	end

	# GET /drills/1 or /drills/1.json
	def show
		@policy = check_policy!(DrillPolicy, record: @drill)

		respond_to do |format|
			@intro = create_fields(helpers.drill_show_intro)
			@steps = create_fields(helpers.drill_show_steps)
			@tail  = create_fields(helpers.drill_show_tail)
			title  = helpers.drill_show_title(title: @drill.name)
			format.pdf do
				response.headers["Content-Disposition"] = "attachment; filename=drill.pdf"
				pdf = drill_to_pdf(title)
				send_data pdf.render(filename: "#{@drill.name}.pdf", type: "application/pdf")
			end
			format.html do
				@title = create_fields(title)
				submit   = edit_path_for(@drill) if @policy.edit?
				@submit  = create_submit(close: :back, retlnk: back_link(default: drills_path(rdx: @rdx)), submit:)
				render :show
			end
		end
	end

	# GET /drills/new
	def new
		@policy = check_policy!(DrillPolicy)

		@drill = Drill.new(sport_id: 1, author: u_person)
		prepare_form("new")
	end

	# GET /drills/1/edit
	def edit
		@policy = check_policy!(DrillPolicy, record: @drill)

		prepare_form("edit")
	end

	# POST /drills or /drills.json
	def create
		@policy = check_policy!(DrillPolicy)

		respond_to do |format|
			@drill = Drill.new
			@drill.rebuild(drill_params)	# rebuild drill
			if @drill.save
				retlnk = path_for(@drill)
				a_desc = "#{I18n.t("drill.created")} '#{@drill.name}'"
				register_action(:created, a_desc, url: path_for(@drill, rdx: 2))
				format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
				format.json { render :index, status: :created, location: retlnk }
			else
				prepare_form("new")
				format.html { render :new }
				format.json { render json: @drill.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /drills/1 or /drills/1.json
	def update
		@policy = check_policy!(DrillPolicy, record: @drill)

		respond_to do |format|
			retlnk = path_for(@drill)
			@drill.rebuild(drill_params)	# rebuild drill
			if @drill.modified?
				if @drill.save
					a_desc = "#{I18n.t("drill.updated")} '#{@drill.name}'"
					register_action(:updated, a_desc, url: path_for(@drill, rdx: 2))
					format.html { redirect_to retlnk, status: :see_other, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
					format.json { render :show, status: :ok, location: retlnk }
				else
					prepare_form("edit")
					format.html { render :edit, status: :unprocessable_entity }
					format.json { render json: @drill.errors, status: :unprocessable_entity }
				end
			else
				format.html { redirect_to retlnk, notice: no_data_notice, data: { turbo_action: "replace" } }
				format.json { render :show, status: :ok, location: retlnk }
			end
		end
	end

	# DELETE /drills/1 or /drills/1.json
	def destroy
		@policy = check_policy!(DrillPolicy, record: @drill)

		d_name = @drill.name
		@drill.destroy
		respond_to do |format|
			a_desc = "#{I18n.t("drill.deleted")} '#{d_name}'"
			register_action(:deleted, a_desc)
			format.html { redirect_to drills_path(rdx: @rdx), notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
			format.json { head :no_content }
		end
	end

	# GET /drills/1/edit_diagram?step_id=X&order=Y
	def edit_diagram
		@policy = check_policy!(DrillPolicy, record: @drill)

		if @step
			@title   = create_fields(helpers.drill_title(title: @drill.name, subtitle: I18n.t("step.edit_diagram") + " ##{@step.order}"))
			@editor  = helpers.drill_form_diagram
			@submit  = create_submit(retlnk: edit_path_for(@drill), frame: :modal)
		else
			redirect_to edit_path_for(@drill), data: { turbo_action: "replace" }
		end
	end

	# GET /drills/1/edit_diagram?step_id=X&order=Y
	def load_diagram
		@policy = check_policy!(DrillPolicy, record: @drill)

		if @step
			@title  = create_fields(helpers.drill_title(title: @drill.name, subtitle: I18n.t("step.load_diagram") + " ##{@step.order}"))
			@loader = create_fields(helpers.drill_form_diagram_file(@step))
			@submit = create_submit(retlnk: edit_path_for(@drill), frame: :modal)
		else
			redirect_to edit_path_for(@drill), data: { turbo_action: "replace" }
		end
	end

	# PATCH /drills/1/update_diagram?step_id=X
	# Recibe el SVG serializado y actualiza el paso
	def update_diagram
		@policy = check_policy!(DrillPolicy, record: @drill)

		diagfile = drill_params.dig(:steps_attributes, :diagram).presence
		if diagfile	# loading an image file
			updated_diag = @step&.update(diagram: diagfile)
		else	# updating an svg diagram
			raw_data     = drill_params[:svgdata]&.strip unless diagfile
			parsed_data  = raw_data.present? ? JSON.parse(raw_data) : nil
			updated_diag = parsed_data && @step&.update(svgdata: parsed_data)
		end

		if updated_diag
			respond_to do |format|
				format.html { redirect_to edit_path_for(@drill), notice: I18n.t("step.diagram") + " ##{@step.order} " + I18n.t("status.saved") }
			end
		else
			redirect_to path_for(@drill, action: edit_diagram, notice: helpers.flash_message(I18n.t("status.no_data")), data: { turbo_action: "replace" }), status: :unprocessable_entity
		end
	end

	# GET /drills/1/versions
	def versions
		@policy = check_policy!(DrillPolicy, record: @drill)

		@title   = create_fields(helpers.drill_versions_title)
		@table   = create_fields(helpers.drill_versions_table)
		@submit  = create_submit(submit: nil)
	end

	private
		# pdf export of @drill content
		def drill_to_pdf(header)
			footer = "#{I18n.t('drill.author')}: #{@drill.coach.person.email}"
			pdf    = pdf_create(header:, footer:)
			pdf_label_text(label: I18n.t("drill.desc"), text: @drill.description) if @drill.description.present?
			pdf_label_text(label: I18n.t("target.many"), text: @drill.print_targets(array: false))
			pdf_separator_line
			pdf_label_text(label: I18n.t("skill.many"), text: @drill.print_skills)
			pdf_separator_line
			@drill.steps.each do |step|
				pdf_rich_text(step.explanation) if @drill&.step_explanation&.present?
				pdf_separator_line
			end
			pdf
		end

		# prepare a drill form calling helpers to get the right FieldComponents
		def prepare_form(action)
			@fields    = create_fields(helpers.drill_form_title(title: I18n.t("drill.#{action}")))
			@court     = @drill.court_mode
			@playbook  = create_fields(helpers.drill_form_playbook(playbook: @drill.playbook))
			@formdata  = create_fields(helpers.drill_form_data)
			@formsteps = create_fields(helpers.drill_form_steps)
			@formtail  = create_fields(helpers.drill_form_tail)
			@skills    = Skill.list
			s_size     = 10
			@skills.each { |skill| s_size = skill.length if skill.length > s_size }
			@s_size    = s_size - 3
			@submit    = create_submit(retlnk: (action == "new" ? drills_path(rdx: @rdx) : path_for(@drill)))
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_drill
			@drill = Drill.includes(:skills, :targets, :steps).find_by_id(params[:id]) unless @drill&.id==params[:id]
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
				:author_id,
				:court_mode,
				:svgdata,
				:step_explanation,
				:playbook,
				:kind_id,
				:order,
				:rdx,
				:season_id,
				:skill_id,
				:step_id,
				skills: [],
				target_ids: [],
				skill_ids: [],
				skills_attributes: [ :id, :concept, :_destroy ],
				steps_attributes: [ :id, :order, :diagram, :svgdata, :explanation, :_destroy ],
				drill_targets_attributes: [
					:id,
					:priority,
					:drill_id,
					:target_id,
					:_destroy,
					target_attributes: [ :id, :aspect, :focus, :concept ]
				]
			)
		end
end
