class CoachesController < ApplicationController
  include Filterable
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_coach, only: [:show, :edit, :update, :destroy]

	# GET /coaches
	# GET /coaches.json
	def index
    check_access(roles: [:admin, :coach])
		@coaches = get_coaches
		@title  = title_fields(I18n.t("coach.many"))
		@title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('coach_filters','search'), url: coaches_path}]
		@grid    = coach_grid
		respond_to do |format|
			format.xlsx {
				response.headers['Content-Disposition'] = "attachment; filename=coaches.xlsx"
			}
			format.html { render :index }
		end
	end

	# GET /coaches/1
	# GET /coaches/1.json
	def show
    check_access(roles: [:admin, :coach])
		@fields = title_fields(I18n.t("coach.single"), icon: @coach.picture, rows: 4, size: "100x100", _class: "rounded-full")
		@fields << [{kind: "label", value: @coach.s_name}]
		@fields << [{kind: "label", value: @coach.person.surname}]
		@fields << [{kind: "string", value: @coach.person.birthday}]
		@fields << [{kind: "label", value: (I18n.t(@coach.active ? "status.active" : "status.inactive")), align: "center"}]
		@grid   = coach_teams_grid
	end

	# GET /coaches/new
	def new
    check_access(roles: [:admin])
		@coach = Coach.new(active: true)
		@coach.build_person
		@title_fields = form_fields(I18n.t("coach.new"), rows: 4, cols: 3)
	end

	# GET /coaches/1/edit
	def edit
		check_access(roles: [:admin, :coach], obj: @coach)
		@title_fields = form_fields(I18n.t("coach.edit"), rows: 4, cols: 3)
	end

	# POST /coaches
	# POST /coaches.json
	def create
    check_access(roles: [:admin])
		respond_to do |format|
			@coach = Coach.new
			@coach.rebuild(coach_params)	# rebuild coach
			if @coach.is_duplicate? then
				format.html { redirect_to coaches_path(search: @coach.s_name), notice: {kind: "info", message: "#{I18n.t("coach.duplicate")} '#{@coach.s_name}'"}, data: {turbo_action: "replace"}}
				format.json { render :index,  :created, location: coaches_path(search: @coach.s_name) }
			else
				if @coach.save # coach saved to database
					if @coach.person.coach_id != @coach.id
						@coach.person.coach_id = @coach.id
						@coach.person.save
					end
					format.html { redirect_to coaches_path(search: @coach.s_name), notice: {kind: "success", message: "#{I18n.t("coach.created")} '#{@coach.s_name}'"}, data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: coaches_path(search: @coach.s_name) }
				else
					format.html { render :new }
					format.json { render json: @coach.errors, status: :unprocessable_entity }
				end
			end
		end
	end

	# PATCH/PUT /coaches/1
	# PATCH/PUT /coaches/1.json
	def update
		check_access(roles: [:admin], obj: @coach)
		respond_to do |format|
			@coach.rebuild(coach_params)
			if @coach.save
				format.html { redirect_to coaches_path(search: @coach.s_name), notice: {kind: "success", message: "#{I18n.t("coach.updated")} '#{@coach.s_name}'"}, data: {turbo_action: "replace"} }
				format.json { render :index, status: :ok, location: coaches_path(search: @coach.s_name) }
			else
				format.html { render :edit }
				format.json { render json: @coach.errors, status: :unprocessable_entity }
			end
		end
	end

	# GET /coaches/import
  # GET /coaches/import.json
	def import
    check_access(roles: [:admin])
	  Coach.import(params[:file])	# added to import excel
	  format.html { redirect_to coaches_path, notice: {kind: "success", message: "#{I18n.t("coach.import")} '#{params[:file].original_filename}'"}, data: {turbo_action: "replace"} }
	end

 	# DELETE /coaches/1
	# DELETE /coaches/1.json
	def destroy
    check_access(roles: [:admin])
		c_name = @coach.s_name
		unlink_person
		@coach.destroy
		respond_to do |format|
			format.html { redirect_to coaches_path, status: :see_other, notice: {kind: "success", message: "#{I18n.t("coach.deleted")} '#{c_name}'"}, data: {turbo_action: "replace"} }
			format.json { head :no_content }
		end
	end

	private

		# return icon and top of FieldsComponent
		def title_fields(title, icon: "coach.svg", rows: 2, cols: nil, size: nil, _class: nil)
			title_start(icon: icon, title: title, rows: rows, size: size, cols: cols, _class: _class)
		end

		# return FieldsComponent @fields for forms
		def form_fields(title, rows: 3, cols: 2)
			res = title_fields(title, icon: @coach.picture, rows: rows, cols: cols, size: "100x100", _class: "rounded-full")
			f_cols = cols>2 ? cols - 1 : nil
			res << [{kind: "label", value: I18n.t("person.name_a")}, {kind: "text-box", key: :name, value: @coach.person.name, cols: f_cols}]
			res << [{kind: "label", value: I18n.t("person.surname_a")}, {kind: "text-box", key: :surname, value: @coach.person.surname, cols: f_cols}]
			res << [{kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @coach.person.birthday, cols: f_cols}]
			@coach_fields  = [
				[{kind: "label-checkbox", label: I18n.t("status.active"), key: :active, value: @coach.active, cols: 4}],
				[{kind: "upload", key: :avatar, label: I18n.t("person.pic"), value: @coach.avatar.filename, cols: 3}]
			]
			@person_fields = [
				[{kind: "label", value: I18n.t("person.pid_a"), align: "right"}, {kind: "text-box", key: :dni, size: 8, value: @coach.person.dni}, {kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: @coach.person.email}],
				[{kind: "icon", value: "user.svg"}, {kind: "text-box", key: :nick, size: 8, value: @coach.person.nick}, {kind: "gap"}, {kind: "icon", value: "phone.svg"}, {kind: "text-box", key: :phone, size: 12, value: @coach.person.phone}]
			]
			res
		end

		# return grid for @coaches GridComponent
    def coach_grid
      title = [
        {kind: "normal", value: I18n.t("person.name")},
        {kind: "normal", value: I18n.t("person.age")},
        {kind: "normal", value: I18n.t("status.active_a")}
      ]
			title << {kind: "add", url: new_coach_path, frame: "modal"} if current_user.admin?

      rows = Array.new
      @coaches.each { |coach|
        row = {url: coach_path(coach), frame: "modal", items: []}
        row[:items] << {kind: "normal", value: coach.to_s}
        row[:items] << {kind: "normal", value: coach.person.age, align: "center"}
        row[:items] << {kind: "icon", value: coach.active? ? "Yes.svg" : "No.svg", align: "center"}
        row[:items] << {kind: "delete", url: row[:url], name: coach.to_s} if current_user.admin?
        rows << row
      }
			{title: title, rows: rows}
    end

		# return grid for @coaches GridComponent
    def coach_teams_grid
      title = []	# Empty title row

      rows = Array.new
      @coach.teams.each { |team|
        row = {url: team_path(team), items: []}
        row[:items] << {kind: "normal", value: team.to_s}
        rows << row
      }
			{title: title, rows: rows}
    end

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
			@coach = Coach.find(params[:id]) unless @coach.try(:id)==params[:id]
		end

		# get coach list depending on the search parameter & user role
		def get_coaches
			if (params[:search] != nil) and (params[:search].length > 0)
				@players = Coach.search(params[:search])
			else
				if current_user.admin? or current_user.is_coach?
					Coach.active
				else
					Coach.none
				end
			end
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def coach_params
			params.require(:coach).permit(:id, :active, :avatar, :retlnk, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :email, :phone])
		end
end
