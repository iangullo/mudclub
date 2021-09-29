class CoachesController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_coach, only: [:show, :edit, :update, :destroy]

	# GET /coaches
	# GET /coaches.json
	def index
		@coaches = Coach.search(params[:search])

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
	end

	# GET /coaches/new
	def new
		@coach=Coach.new
		@coach.build_person
	end

	# GET /coaches/1/edit
	def edit
	end

	# POST /coaches
	# POST /coaches.json
	def create
		respond_to do |format|
			@coach = rebuild_coach(params)	# rebuild coach
			if @coach.is_duplicate? then
				format.html { redirect_to coaches_url, notice: 'Ya existía este entrenador.'}
				format.json { render :index,  :created, location: coaches_url }
			else
				@coach.person.save
				@coach.person_id = @coach.person.id
				if @coach.save # coach saved to database
					if @coach.person.coach_id != @coach.id
						@coach.person.coach_id = @coach.id
					end
					format.html { redirect_to coaches_url, notice: 'Entrenador creado.' }
					format.json { render :index, status: :created, location: coaches_url }
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
		respond_to do |format|
			if @coach.update(coach_params)
				format.html { redirect_to coaches_url, notice: 'Entrenador actualizado.' }
				format.json { render :index, status: :ok, location: coaches_url }
			else
				format.html { render :edit }
				format.json { render json: @coach.errors, status: :unprocessable_entity }
			end
		end
	end

	# GET /coaches/import
  # GET /coaches/import.json
	def import
		# added to import excel
    Coach.import(params[:file])
    redirect_to coaches_url
	end

 	# DELETE /coaches/1
	# DELETE /coaches/1.json
	def destroy
		unlink_person
		@coach.destroy
		respond_to do |format|
			format.html { redirect_to coaches_url, notice: 'Entrenador borrado.' }
			format.json { head :no_content }
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
			format.html { render :new, notice: 'Datos del entrenador leídos.' }
			format.json { render :new, status: :ok }
		end
	end

	# save a coach - ensuring duplicates not existing
	def	save_data(format)
		if @coach.save
			format.html { redirect_to coaches_url, notice: 'Entrenador creado.' }
			format.json { render :index, status: :created, location: coaches_url }
		else
			format.html { render :new }
			format.json { render json: @coach.errors, status: :unprocessable_entity }
		end
	end

	private
	# Use callbacks to share common setup or constraints between actions.
	def set_coach
		@coach = Coach.find(params[:id])
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def coach_params
		params.require(:coach).permit(:id, :active, :avatar, :teams, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :email, :phone])
	end

	# De-couple from associated person
	def unlink_person
		if @coach.person.coach_id == @coach.id
			p = @coach.person
			p.coach=Coach.find(0)	# map to empty coach
			p.save
			@coach.person_id = 0	# map to empty person
		end
	end
end
