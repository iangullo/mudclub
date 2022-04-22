class PeopleController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_person, only: [:show, :edit, :update, :destroy]

  # GET /people
  # GET /people.json
  def index
		if current_user.present? and current_user.admin?
			@people = Person.search(params[:search])
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
  end

  # GET /people/new
  def new
		if current_user.present? and current_user.admin?
			@person = Person.new(coach_id: 0, player_id: 0)
		else
			redirect_to "/"
		end
  end

  # GET /people/1/edit
  def edit
		unless current_user.present? and (current_user.admin? or current_user.person_id==@person.id)
			redirect_to "/"
		end
  end

  # POST /people
  # POST /people.json
  def create
		if current_user.present? and current_user.admin?
    	@person = Person.new(person_params)

			# added to import excel
	    respond_to do |format|
	      if @person.save
	        format.html { redirect_to people_url }
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
	        format.html { redirect_to people_url }
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
    	redirect_to people_url
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
	      format.html { redirect_to people_url }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/"
		end
  end

  private
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def person_params
			params.require(:person).permit(:id, :dni, :nick, :name, :surname, :birthday, :female, :email, :phone, :player_id, :coach_id, :user_id)
    end

		def set_person
			 @person = Person.find(params[:id]) unless @person.try(:id)==params[:id]
		end
end
