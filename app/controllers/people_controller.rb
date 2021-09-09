class PeopleController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_person, only: [:show, :edit, :update, :destroy]

  # GET /people
  # GET /people.json
  def index
    @people = Person.search(params[:search])

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
  end

  # GET /people/new
  def new
    @person = Person.new(coach_id: 0, player_id: 0)
  end

  # GET /people/1/edit
  def edit
  end

  # POST /people
  # POST /people.json
  def create
    @person = Person.new(person_params)

		# added to import excel
    respond_to do |format|
      if @person.save
        format.html { redirect_to people_url, notice: 'Persona creada.' }
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
    respond_to do |format|
      if @person.update(person_params)
        format.html { redirect_to people_url, notice: 'Persona #{@person.to_s} actualizada.' }
				format.json { render :index, status: :created, location: people_url }
      else
        format.html { render :edit }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /people/import
  # GET /people/import.json
	def import
		# added to import excel
    Person.import(params[:file])
    redirect_to people_url
	end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
    @person.destroy
    respond_to do |format|
      format.html { redirect_to people_url, notice: 'Persona borrada.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_person
      @person = Person.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def person_params
      params.require(:person).permit(:dni, :nick, :name, :surname, :birthday, :female, :player_id, :coach_id)
    end
end
