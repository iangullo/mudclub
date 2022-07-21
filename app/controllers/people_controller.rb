class PeopleController < ApplicationController
  include Filterable
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_person, only: [:show, :edit, :update, :destroy]

  # GET /people
  # GET /people.json
  def index
		if current_user.present? and current_user.admin?
			@people = get_people
			@title  = title_fields(I18n.t("person.many"))
			@title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('people_filters','search'), url: people_path}]
			@grid   = person_grid
			respond_to do |format|
				format.xlsx {
					response.headers['Content-Disposition'] = "attachment; filename=people.xlsx"
				}
				format.html { render :index }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

  # GET /people/1
  # GET /people/1.json
  def show
		unless current_user.present? and (current_user.admin? or current_user.person_id==@person.id)
			redirect_to "/", data: {turbo_action: "replace"}
		end
		@fields = title_fields(I18n.t("person.single"), icon: @person.picture, size: "100x100", rows: 4, _class: "rounded-full")
		@fields << [{kind: "label", value: @person.s_name}]
		@fields << [{kind: "label", value: @person.surname}]
		@fields << [{kind: "string", value: @person.birthday}]
		@fields << [{kind: "string", value: @person.dni, align: "center"}]
		@fields.last << {kind: "icon", value: "player.svg"} if @person.player_id > 0
		@fields.last << {kind: "icon", value: "coach.svg"} if @person.coach_id > 0
  end

  # GET /people/new
  def new
		if current_user.present? and current_user.admin?
			@person        = Person.new(coach_id: 0, player_id: 0)
			@title_fields  = form_fields(I18n.t("person.new"))
			@picture_field = form_file_field(label: I18n.t("person.pic"), key: :avatar, cols: 2)
			@person_fields = person_fields
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

  # GET /people/1/edit
  def edit
		unless current_user.present? and (current_user.admin? or current_user.person_id==@person.id)
			redirect_to "/", data: {turbo_action: "replace"}
		end
		@title_fields  = form_fields(I18n.t("person.edit"))
		@picture_field = form_file_field(label: I18n.t("person.pic"), key: :avatar, cols: 2)
		@person_fields = person_fields
  end

  # POST /people
  # POST /people.json
  def create
		if current_user.present? and current_user.admin?
    	@person = Person.new(person_params)

	    respond_to do |format|
	      if @person.save
	        format.html { redirect_to people_url(search: @person.name), notice: {kind: "success", message: "#{I18n.t("person.created")} '#{@person.to_s}'"}, data: {turbo_action: "replace"} }
	        format.json { render :index, status: :created, location: people_url }
	      else
	        format.html { render :new }
	        format.json { render json: @person.errors, status: :unprocessable_entity }
	      end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
    end
  end

  # PATCH/PUT /people/1
  # PATCH/PUT /people/1.json
  def update
		if current_user.present? and (current_user.admin? or current_user.person_id==@person.id)
    	respond_to do |format|
      	if @person.update(person_params)
					if @person.id=0 # just edited the club identity
						format.html { redirect_to "/", notice: {kind: "success", message: "'#{@person.nick}' #{I18n.t("status.saved")}"}, data: {turbo_action: "replace"} }
						format.json { render "/", status: :created, location: home_url }
					else
		        format.html { redirect_to people_url(search: @person.name), notice: {kind: "success", message: "#{I18n.t("person.updated")} '#{@person.to_s}'"}, data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: people_url }
					end
	      else
	        format.html { render :edit }
	        format.json { render json: @person.errors, status: :unprocessable_entity }
	      end
			end
		else
			redirect_to "/"
    end
  end

  # GET /people/import
  # GET /people/import.json
	def import
		if current_user.present? and current_user.admin?
			# added to import excel
    	Person.import(params[:file])
			format.html { redirect_to people_url, notice: {kind: "success", message: "#{I18n.t("person.import")} '#{params[:file].original_filename}'"}, data: {turbo_action: "replace"} }
		else
			redirect_to "/"
		end
	end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
		if current_user.present? and current_user.admin?
			erase_links
			@person.destroy
	    respond_to do |format|
				format.html { redirect_to people_url, status: :see_other, notice: {kind: "success", message: "#{I18n.t("person.deleted")} '#{@person.to_s}'"}, data: {turbo_action: "replace"} }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/"
		end
  end

  private

		# return icon and top of FieldsComponent
		def title_fields(title, icon: "person.svg", rows: 2, cols: 2, size: nil, _class: nil)
			title_start(icon: icon, title: title, rows: rows, cols: cols, size: size, _class: _class)
		end

		# return FieldsComponent @fields for forms
		def form_fields(title)
			res = title_fields(title, icon: @person.picture, rows: 4, cols: 2, size: "100x100", _class: "rounded-full")
			res << [{kind: "label", value: I18n.t("person.name_a")}, {kind: "text-box", key: :name, value: @person.name}]
			res << [{kind: "label", value: I18n.t("person.surname_a")}, {kind: "text-box", key: :surname, value: @person.surname}]
			res << [{kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @person.birthday}]
			res << [{kind: "label-checkbox", label: I18n.t("sex.fem_a"), key: :female, value: @person.female, align: "center"}]
			res
		end

		# return title for @people GridComponent
    def person_grid
      title = [{kind: "normal", value: I18n.t("person.name")}]
			title << {kind: "add", url: new_person_path, frame: "modal"} if current_user.admin?

      rows = Array.new
      @people.each { |person|
        row = {url: person_path(person), frame: "modal", items: []}
        row[:items] << {kind: "normal", value: person.to_s}
        row[:items] << {kind: "delete", url: row[:url], name: person.to_s} if current_user.admin?
        rows << row
      }
			{title: title, rows: rows}
    end

		def person_fields
			res = [
				[{kind: "label", value: I18n.t("person.pid_a"), align: "right"}, {kind: "text-box", key: :dni, size: 8, value: @person.dni}, {kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: @person.email}],
				[{kind: "icon", value: "user.svg"}, {kind: "text-box", key: :nick, size: 8, value: @person.nick}, {kind: "gap"}, {kind: "icon", value: "phone.svg"}, {kind: "text-box", key: :phone, size: 12, value: @person.phone}]
			]
		end

		# Delete associated players/coaches
		def erase_links
			erase_coach if @person.coach_id > 0	# delete associated coach
			erase_player if @person.player_id > 0	# delete associated player
			erase_user if @person.user_id > 0	# unlink associated user
		end

		def erase_coach
			c = @person.coach
			c.person_id = 0
			c.save
			@person.coach_id = 0
			@person.save
			c.destroy
		end

		def erase_player
			p = @person.player
			p.person_id = 0
			p.save
			@person.player_id = 0
			@person.save
			p.destroy
		end

		def erase_user
			u = @person.user
			u.person_id = 0
			u.save
			@person.user_id = 0
			@person.save
			u.destroy
		end

		def set_person
			 @person = Person.find(params[:id]) unless @person.try(:id)==params[:id]
		end

		# get player list depending on the search parameter & user role
		def get_people
			if (params[:search] != nil) and (params[:search].length > 0)
				Person.search(params[:search])
			else
				Person.none
			end
		end

    # Never trust parameters from the scary internet, only allow the white list through.
    def person_params
			params.require(:person).permit(:id, :dni, :nick, :name, :surname, :birthday, :female, :email, :phone, :player_id, :coach_id, :user_id, :avatar)
    end
end
