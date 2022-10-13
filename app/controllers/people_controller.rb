class PeopleController < ApplicationController
	include Filterable
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_person, only: [:show, :edit, :update, :destroy]

	# GET /people
	# GET /people.json
	def index
		check_access(roles: [:admin])
		@people = get_people
		@title  = helpers.person_title_fields(title: I18n.t("person.many"))
		@title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('people_filters','search'), url: people_path}]
		@grid   = helpers.person_grid(people: @people)
		respond_to do |format|
			format.xlsx {
				response.headers['Content-Disposition'] = "attachment; filename=people.xlsx"
			}
			format.html { render :index }
		end
	end

	# GET /people/1
	# GET /people/1.json
	def show
		check_access(roles: [:admin], obj: @person)
		@fields = helpers.person_show_fields(person: @person)
	end

	# GET /people/new
	def new
		check_access(roles: [:admin])
		@person = Person.new(coach_id: 0, player_id: 0)
		prepare_form(title: I18n.t("person.new"))
	end

	# GET /people/1/edit
	def edit
		check_access(roles: [:admin], obj: @person)
		prepare_form(title: I18n.t("person.edit"))
	end

	# POST /people
	# POST /people.json
	def create
		check_access(roles: [:admin])
	 	@person = Person.new
		respond_to do |format|
			@person.rebuild(person_params)	# take care of duplicates
			if @person.persisted?	# it was a duplicate
				format.html { redirect_to people_url(search: @person.name), notice: helpers.flash_message("#{I18n.t("person.duplicate")} '#{@person.to_s}'", "success"), data: {turbo_action: "replace"} }
				format.json { render :index, status: :duplicate, location: people_url }
			elsif @person.save
				format.html { redirect_to people_url(search: @person.name), notice: helpers.flash_message("#{I18n.t("person.created")} '#{@person.to_s}'", "success"), data: {turbo_action: "replace"} }
				format.json { render :index, status: :created, location: people_url }
			else
				format.html { render :new }
				format.json { render json: @person.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /people/1
	# PATCH/PUT /people/1.json
	def update
		check_access(roles: [:admin], obj: @person)
		respond_to do |format|
			if @person.update(person_params)
				if @person.id=0 # just edited the club identity
					format.html { redirect_to "/", notice: helpers.flash_message("'#{@person.nick}' #{I18n.t("status.saved")}", "success"), data: {turbo_action: "replace"} }
					format.json { render "/", status: :created, location: home_url }
				else
					format.html { redirect_to people_url(search: @person.name), notice: helpers.flash_message("#{I18n.t("person.updated")} '#{@person.to_s}'", "success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: people_url }
				end
			else
				format.html { render :edit }
				format.json { render json: @person.errors, status: :unprocessable_entity }
			end
		end
	end

	# GET /people/import
	# GET /people/import.json
	def import
		check_access(roles: [:admin])
	 	Person.import(params[:file]) # added to import excel
		format.html { redirect_to people_url, notice: helpers.flash_message("#{I18n.t("person.import")} '#{params[:file].original_filename}'", "success"), data: {turbo_action: "replace"} }
	end

	# DELETE /people/1
	# DELETE /people/1.json
	def destroy
		check_access(roles: [:admin])
		erase_links
		@person.destroy
		respond_to do |format|
			format.html { redirect_to people_url, status: :see_other, notice: helpers.flash_message("#{I18n.t("person.deleted")} '#{@person.to_s}'"), data: {turbo_action: "replace"} }
			format.json { head :no_content }
		end
	end

	private
		# prepare form FieldComponents
		def prepare_form(title:)
			@title_fields  = helpers.person_form_title(title:, person: @person)
			@picture_field = helpers.form_file_field(label: I18n.t("person.pic"), key: :avatar, value: @person.picture, cols: 2)
			@person_fields = helpers.person_form_fields(person: @person)
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
