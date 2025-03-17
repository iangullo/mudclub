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
# Managament of drills/plays sotredin the server
class DrillsController < ApplicationController
	include Filterable
	include PdfGenerator
	before_action :set_drill, only: [:show, :edit, :update, :destroy, :versions]
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
				@tail  = create_fields(helpers.drill_show_tail)
				title  = helpers.drill_show_title(title: I18n.t("drill.single"))
				format.pdf do
					response.headers['Content-Disposition'] = "attachment; filename=drill.pdf"
					pdf = drill_to_pdf(title)
					send_data pdf.render(filename: "#{@drill.name}.pdf", type: "application/pdf")
				end
				format.html do
					@title = create_fields(title)
					@explain = create_fields(helpers.drill_show_explain)
					submit   = edit_drill_path(@drill, rdx: @rdx) if (@drill.coach_id == u_coachid) || (u_manager? && u_clubid == @drill.coach.club_id)
					@submit  = create_submit(close: "back", retlnk: base_lnk(drills_path(rdx: @rdx)), submit:)
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
			@drill = Drill.new
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
			@title    = create_fields(helpers.drill_form_title(title: I18n.t("drill.#{action}")))
			@playbook = create_fields(helpers.drill_form_playbook(playbook: @drill.playbook))
			@formdata = create_fields(helpers.drill_form_data)
			@explain  = create_fields(helpers.drill_form_explain)
			@formtail = create_fields(helpers.drill_form_tail)
			@skills   = Skill.list
			s_size    = 10
			@skills.each { |skill| s_size = skill.length if skill.length > s_size }
			@s_size   = s_size - 3
			@submit   = create_submit(retlnk: (action == "new" ? drills_path(rdx: @rdx) : cru_return))
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_drill
			@drill = Drill.includes(:skills,:targets,:steps).find_by_id(params[:id]) unless @drill&.id==params[:id]
		end

		# Only allow a list of trusted parameters through.
		def drill_params
			params.require(:drill).permit(
				:name,
				:material,
				:description,
				:coach_id,
				:step_explanation,
				:playbook,
				:kind_id,
				:rdx,
				:season_id,
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
