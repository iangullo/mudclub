class DrillsController < ApplicationController
  include Filterable
	before_action :set_drill, only: [:show, :edit, :update, :destroy]
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :edit, :update, :check_reload]

	# GET /drills or /drills.json
	def index
		check_access(roles: [:admin, :coach])
		# Simple search by name/description for now
		@title  = title_fields(I18n.t("drill.many"))
#			@title << [{kind: "subtitle", value: I18n.t("catalog")}]
    @search = drill_search_bar(drills_path)
		@drills = filter!(Drill)
		@grid   = GridComponent.new(grid: drill_grid)
	end

	# GET /drills/1 or /drills/1.json
	def show
		check_access(roles: [:admin, :coach])
		@title  = title_fields(I18n.t("drill.single"))
		@title.last << {kind: "link", align: "right", icon: "playbook.png", size: "20x20", url: rails_blob_path(@drill.playbook, disposition: "attachment"), label: "Playbook"} if @drill.playbook.attached?
		@title << [{kind: "subtitle", value: @drill.name}, {kind: "string", value: "(" + @drill.kind.name + ")", cols: 2}]
		@intro  = [[{kind: "label", value: I18n.t("target.many")}, {kind: "lines", class: "align-top", value: @drill.drill_targets}]]
		@intro << [{kind: "label", value: I18n.t("drill.material")}, {kind: "string", value: @drill.material}]
		@intro << [{kind: "label", value: I18n.t("drill.desc_a")}, {kind: "string", value: @drill.description}]
		@explain = [[{kind: "string", value: @drill.explanation}]]
		@tail = [[{kind: "label", value: I18n.t("skill.abbr")}, {kind: "string", value: @drill.print_skills}]]
		@tail << [{kind: "label", value: I18n.t("drill.author")}, {kind: "string", value: @drill.coach.s_name}]
	end

	# GET /drills/new
	def new
		check_access(roles: [:admin, :coach])
		@drill = Drill.new
		@title = title_fields(I18n.t("drill.new"))
		@form_fields = form_fields
	end

	# GET /drills/1/edit
	def edit
		check_access(roles: [:admin], obj: @drill, returl: drills_url)
		@title       = title_fields(I18n.t("drill.edit"))
		@form_fields = form_fields
	end

	# POST /drills or /drills.json
	def create
		check_access(roles: [:admin, :coach])
		respond_to do |format|
			@drill = Drill.new
			rebuild_drill	# rebuild drill
			if @drill.save
				format.html { redirect_to drills_url, notice: {kind: "success", message: "#{I18n.t("drill.created")} '#{@drill.name}'"}, data: {turbo_action: "replace"} }
				format.json { render :index, status: :created, location: @drill }
			else
				format.html { render :new }
				format.json { render json: @drill.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /drills/1 or /drills/1.json
	def update
		check_access(roles: [:admin], obj: @drill, returl: drills_url)
		respond_to do |format|
			rebuild_drill	# rebuild drill
		 	if @drill.save
				format.html { redirect_to drill_path, status: :see_other, notice: {kind: "success", message: "#{I18n.t("drill.updated")} '#{@drill.name}'"}, data: {turbo_action: "replace"} }
				format.json { render :show, status: :ok, location: @drill }
			else
				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @drill.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /drills/1 or /drills/1.json
	def destroy
		check_access(roles: [:admin])
		d_name = @drill.name
		@drill.drill_targets.each { |d_t| d_t.delete }
		@drill.destroy
		respond_to do |format|
			format.html { redirect_to drills_url, notice: {kind: "success", message: "#{I18n.t("drill.deleted")} '#{d_name}'"}, data: {turbo_action: "replace"} }
			format.json { head :no_content }
		end
	end

	private

		# return icon and top of FieldsComponent
		def title_fields(title, rows: nil, cols: nil)
			title_start(icon: "drill.svg", title: title, rows: rows, cols: cols)
		end

		# return FormComponent @fields for edit/new
		def form_fields
			@title << [{kind: "text-box", key: :name, value: @drill.name}, {kind: "select-collection", key: :kind_id, options: Kind.all, value: @drill.kind_id, align: "center"}]
			@playbook  = [[{kind: "upload", icon: "playbook.png", label: "Playbook", key: :playbook, value: @drill.playbook.filename}]]
			@explain   = [[{kind: "rich-text-area", key: :explanation, align: "left", cols: 3}]]
			@author    = [[{kind: "label", value: I18n.t("drill.author"), align: "right"}, {kind: "select-collection", key: :coach_id, options: Coach.real, value: @drill.coach_id ? @drill.coach_id : 1}]]
			return [
				# DO WE INCLUDE NESTED FORM TYPE??? HOW?
				# NESTED FORM for Targets...
				[{kind: "label", value: I18n.t("drill.material"), align: "right"}, {kind: "text-box", key: :material, size: 33, value: @drill.material}],
				[{kind: "label", value: I18n.t("drill.desc_a"), align: "right"}, {kind: "text-area", key: :description, size: 30, lines: 2, value: @drill.description}],
				# NESTED FORM for Skills...
			]
		end

		# return grid for @drills GridComponent
	  def drill_grid
			track = {s_url: drills_path, s_filter: "drill_filters"}
	    title = [
				{kind: "normal", value: I18n.t("drill.name"), sort: (session.dig('drill_filters', 'name') == "name"), order_by: "name"},
	      {kind: "normal", value: I18n.t("kind.single"), align: "center", sort: (session.dig('drill_filters', 'kind_id') == "kind_id"), order_by: "kind_id"},
	      {kind: "normal", value: I18n.t("target.many")}
	    ]
			title << {kind: "add", url: new_drill_path, frame: "_top"} if current_user.admin? or current_user.is_coach?

			{track: track, title: title, rows: drill_rows}
	  end

		# get the grid rows for @drills
		def drill_rows
			rows = Array.new
			@drills.each { |drill|
	      row = {url: drill_path(drill), items: []}
	      row[:items] << {kind: "normal", value: drill.name}
	      row[:items] << {kind: "normal", value: drill.kind.name, align: "center"}
	      row[:items] << {kind: "lines", value: drill.print_targets}
	      row[:items] << {kind: "delete", url: row[:url], name: drill.name} if current_user.admin?
	      rows << row
	    }
			rows
		end

		# build new @drill from raw input given by submittal from "new"
		# return nil if unsuccessful
		def rebuild_drill
			p_data = params.fetch(:drill)
			@drill.name        = p_data[:name]
			@drill.description = p_data[:description]
			@drill.material    = p_data[:material]
			@drill.coach_id    = p_data[:coach_id]
			@drill.kind_id     = p_data[:kind_id]
			@drill.explanation = p_data[:explanation]
			@drill.playbook    = p_data[:playbook]
			@drill.check_skills(p_data[:skills_attributes]) if p_data[:skills_attributes]
			@drill.check_targets(p_data[:drill_targets_attributes]) if p_data[:drill_targets_attributes]
			@drill
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_drill
			@drill = Drill.find(params[:id]) unless @drill.try(:id)==params[:id]
		end

		# Only allow a list of trusted parameters through.
		def drill_params
			params.require(:drill).permit(:name, :material, :description, :coach_id, :explanation, :playbook, :kind_id, :skill_id, skills: [], target_ids: [], skill_ids: [], skills_attributes: [:id, :concept, :_destroy], drill_targets_attributes: [:id, :priority, :drill_id, :target_id, :_destroy], targets_attributes: [:id, :concept])
		end
end
