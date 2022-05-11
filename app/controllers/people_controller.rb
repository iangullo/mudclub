class PeopleController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_person, only: [:show, :edit, :update, :destroy]

  # GET /people
  # GET /people.json
  def index
		if current_user.present? and current_user.admin?
			@people = Person.search(params[:search])
			@fields = header_fields(I18n.t(:l_per_index))
			@fields << [{kind: "search-text", url: people_path}]
			@g_head = grid_header
      @g_rows = grid_rows
			respond_to do |format|
				format.xlsx {
					response.headers['Content-Disposition'] = "attachment; filename=people.xlsx"
				}
				format.html { render :index }
			end
		else
			redirect_to "/"
		end
  end

  # GET /people/1
  # GET /people/1.json
  def show
		unless current_user.present? and (current_user.admin? or current_user.person_id==@person.id)
			redirect_to "/"
		end
		@fields = header_fields(I18n.t(:l_per_show), icon: @person.picture, size: "100x100", rows: 4, _class: "rounded-full")
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
			@person = Person.new(coach_id: 0, player_id: 0)
			@header_fields = form_fields(I18n.t(:l_per_new))
			@person_fields = person_fields
		else
			redirect_to "/"
		end
  end

  # GET /people/1/edit
  def edit
		unless current_user.present? and (current_user.admin? or current_user.person_id==@person.id)
			redirect_to "/"
		end
		@header_fields = form_fields(I18n.t(:l_per_edit))
		@person_fields = person_fields
  end

  # POST /people
  # POST /people.json
  def create
		if current_user.present? and current_user.admin?
    	@person = Person.new(person_params)

			# added to import excel
	    respond_to do |format|
	      if @person.save
	        format.html { redirect_to people_url, notice: t(:per_created) + "'#{@person.to_s}'" }
	        format.json { render :index, status: :created, location: people_url }
	      else
	        format.html { render :new }
	        format.json { render json: @person.errors, status: :unprocessable_entity }
	      end
			end
		else
			redirect_to "/"
    end
  end

  # PATCH/PUT /people/1
  # PATCH/PUT /people/1.json
  def update
		if current_user.present? and (current_user.admin? or current_user.person_id==@person.id)
    	respond_to do |format|
      	if @person.update(person_params)
	        format.html { redirect_to people_url, notice: t(:per_updated) + "'#{@person.to_s}'" }
					format.json { render :index, status: :created, location: people_url }
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
			format.html { redirect_to people_url, notice: t(:per_import) + "'#{params[:file]}'"}
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
				format.html { redirect_to people_url, notice: t(:per_deleted) + "'#{@person.to_s}'" }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/"
		end
  end

  private

		# return icon and top of FieldsComponent
		def header_fields(title, icon: "person.svg", rows: 2, cols: 2, size: nil, _class: nil)
			[[{kind: "header-icon", value: icon, rows: rows, size: size, class: _class}, {kind: "title", value: title, cols: cols}]]
		end

		# return FieldsComponent @fields for forms
		def form_fields(title)
			res = header_fields(title, icon: @person.picture, rows: 4, cols: 2, size: "100x100", _class: "rounded-full")
			res << [{kind: "label", value: I18n.t(:l_name)}, {kind: "text-box", key: :name, value: @person.name}]
			res << [{kind: "label", value: I18n.t(:l_surname)}, {kind: "text-box", key: :surname, value: @person.surname}]
			res << [{kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @person.birthday}]
			res
		end

		# return header for @categories GridComponent
    def grid_header
      res = [
        {kind: "normal", value: I18n.t(:h_name)},
      ]
			res << {kind: "add", url: new_person_path, modal: true} if current_user.admin?
    end

    # return content rows for @categories GridComponent
    def grid_rows
      res = Array.new
      @people.each { |person|
        row = {url: person_path(person), modal: true, items: []}
        row[:items] << {kind: "normal", value: person.to_s}
        row[:items] << {kind: "delete", url: person, name: person.to_s} if current_user.admin?
        res << row
      }
      res
    end

		def person_fields
			res = [
				[{kind: "label-checkbox", label: I18n.t(:l_fem), key: :female, value: @person.female, cols: 4}],
				[{kind: "label", value: I18n.t(:l_pic)}, {kind: "select-file", key: :avatar, cols: 4}],
				[{kind: "label", value: I18n.t(:l_id), align: "right"}, {kind: "text-box", key: :dni, size: 8, value: @person.dni}, {kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: @person.email}],
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def person_params
			params.require(:person).permit(:id, :dni, :nick, :name, :surname, :birthday, :female, :email, :phone, :player_id, :coach_id, :user_id)
    end
end
