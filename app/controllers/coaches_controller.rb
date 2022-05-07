class CoachesController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_coach, only: [:show, :edit, :update, :destroy]

	# GET /coaches
	# GET /coaches.json
	def index
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@coaches = get_coaches
			@header = header_top(I18n.t(:l_coach_index))
			@header << [{kind: "text-search", url: coaches_path}]
			respond_to do |format|
				format.xlsx {
					response.headers['Content-Disposition'] = "attachment; filename=coaches.xlsx"
				}
				format.html { render :index }
			end
		else
			redirect_to "/"
		end
	end

	# GET /coaches/1
	# GET /coaches/1.json
	def show
		unless current_user.present? and (current_user.admin? or current_user.is_coach?)
			redirect_to "/"
		end
		@header = header_top(I18n.t(:l_coach_show), 4, nil, "100x100", "rounded-full")
		@header << [{kind: "label", value: @coach.person.nick}]
		@header << [{kind: "label", value: @coach.person.surname}]
		@header << [{kind: "text", value: @coach.person.birthday}]
		@header << [{kind: "label", value: (I18n.t(@coach.active ? :h_active : :h_inactive)), align: "center"}]
	end

	# GET /coaches/new
	def new
		if current_user.present? and current_user.admin?
			@coach = Coach.new
			@coach.build_person
			@header = form_header(I18n.t(:l_coach_edit), 3, 2)
		else
			redirect_to "/"
		end
	end

	# GET /coaches/1/edit
	def edit
		unless current_user.present? and (current_user.admin? or current_user.person.coach_id==@coach.id)
			redirect_to "/"
		else
			@header       = form_header(I18n.t(:l_coach_edit), 4, 3)
			@coach_fields = [
				[{kind: "label-checkbox", label: I18n.t(:h_active), key: :active, value: @coach.active, cols: 4}],
				[{kind: "label", value: I18n.t(:l_pic)}, {kind: "select-file", key: :avatar, cols: 3}]
			]
			@person_fields = [
				[{kind: "label", value: I18n.t(:l_id), align: "right"}, {kind: "text-box", key: :dni, size: 8, value: @coach.person.dni}, {kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "text-box", key: :email, size: 22, value: @coach.person.email}],
				[{kind: "icon", value: "user.svg"}, {kind: "text-box", key: :nick, size: 8, value: @coach.person.nick}, {kind: "gap"}, {kind: "icon", value: "phone.svg"}, {kind: "text-box", key: :phone, size: 12, value: @coach.person.phone}]
			]
		end
	end

	# POST /coaches
	# POST /coaches.json
	def create
		if current_user.present? and current_user.admin?
			respond_to do |format|
				@coach = rebuild_coach(params)	# rebuild coach
				if @coach.is_duplicate? then
					format.html { redirect_to coaches_url, notice: t(:coach_duplicate) + "'#{@coach.s_name}'" }
					format.json { render :index,  :created, location: coaches_url }
				else
					@coach.person.save
					@coach.person_id = @coach.person.id
					if @coach.save # coach saved to database
						if @coach.person.coach_id != @coach.id
							@coach.person.coach_id = @coach.id
						end
						format.html { redirect_to coaches_url, notice: t(:coach_created) + "'#{@coach.s_name}'" }
						format.json { render :index, status: :created, location: coaches_url }
					else
						format.html { render :new }
						format.json { render json: @coach.errors, status: :unprocessable_entity }
					end
				end
			end
		else
			redirect_to "/"
		end
	end

	# PATCH/PUT /coaches/1
	# PATCH/PUT /coaches/1.json
	def update
		if current_user.present? and (current_user.admin? or current_user.coach_id==@coach.id)
			respond_to do |format|
				if @coach.update(coach_params)
					format.html { redirect_to coaches_url, notice: t(:coach_updated) + "'#{@coach.s_name}'" }
					format.json { render :index, status: :ok, location: coaches_url }
				else
					format.html { render :edit }
					format.json { render json: @coach.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/"
		end
	end

	# GET /coaches/import
  # GET /coaches/import.json
	def import
		if current_user.present? and current_user.admin?
			# added to import excel
	    Coach.import(params[:file])
	    format.html { redirect_to coaches_url, notice: t(:coach_import) + "'#{params[:file]}'"}
		else
			redirect_to "/"
		end
	end

 	# DELETE /coaches/1
	# DELETE /coaches/1.json
	def destroy
		if current_user.present? and current_user.admin?
			c_name = @coach.s_name
			unlink_person
			@coach.destroy
			respond_to do |format|
				format.html { redirect_to coaches_url, notice: t(:coach_deleted) + "'#{c_name}'" }
				format.json { head :no_content }
			end
		else
			redirect_to "/"
		end
	end

	# build new @coach from raw input given by submittal from "new"
	# return nil if unsuccessful
	def rebuild_coach(params)
		@coach = Coach.new
		@coach.build_person
		@coach.active = true
		p_data= params.fetch(:coach).fetch(:person_attributes)
		@coach.person[:dni] = p_data[:dni]
		@coach.person[:nick] = p_data[:nick]
		@coach.person[:name] = p_data[:name]
		@coach.person[:surname] = p_data[:surname]
		@coach.person[:female] = p_data[:female]
		@coach.person[:email] = p_data[:email]
		@coach.person[:phone] = Phonelib.parse(p_data[:phone]).international.to_s
		@coach.person[:coach_id] = 0
		@coach.person[:player_id] = 0
		@coach
	end

	# reload edit/create form if person exists without a coach record
	def reload_data(format)
		if @coach.person.coach_id==0
			format.html { render :new }
			format.json { render :new, status: :ok }
		end
	end

	# save a coach - ensuring duplicates not existing
	def	save_data(format)
		if @coach.save
			format.html { redirect_to coaches_url, notice: "Entrenador '#{@coach.s_name}' guardado." }
			format.json { render :index, status: :created, location: coaches_url }
		else
			format.html { render :new }
			format.json { render json: @coach.errors, status: :unprocessable_entity }
		end
	end

	private

	# return icon and top of HeaderComponent
	def header_top(title, rows=2, cols=nil, size=nil, _class=nil)
		[[{kind: "header-icon", value: "coach.svg", rows: rows, size: size, class: _class}, {kind: "title", value: title, cols: cols}]]
	end

	# return HeaderComponent @header for forms
	def form_header(title, rows=3, cols=2)
		res = header_top(title, rows, cols, "100x100", "rounded-full")
		f_cols = cols>2 ? cols - 1 : nil
		res << [{kind: "label", value: I18n.t(:l_name)}, {kind: "text-box", key: :name, value: @coach.person.name, cols: f_cols}]
		res << [{kind: "label", value: I18n.t(:l_surname)}, {kind: "text-box", key: :surname, value: @coach.person.surname, cols: f_cols}]
		if f_cols	# i's an edit form
			res << [{kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @coach.person.birthday, cols: f_cols}]
		end
		res
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
		params.require(:coach).permit(:id, :active, :avatar, :teams, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :email, :phone])
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
end
