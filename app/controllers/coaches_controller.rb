class CoachesController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_coach, only: [:show, :edit, :update, :destroy]

	# GET /coaches
	# GET /coaches.json
	def index
		@coaches = Coach.search(params[:search])
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
				format.html { redirect_to @coach, notice: 'Ya existía este entrenador.'}
				format.json { render :show,  :created, location: @coach }
			else
				@coach.person.save
				@coach.person_id = @coach.person.id
				if @coach.save # coach saved to database
					if @coach.person.coach_id != @coach.id
						@coach.person.coach_id = @coach.id
					end
					format.html { render :edit, notice: 'Entrenador creado.' }
					format.json { render :edit, status: :created, location: @coach }
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
				format.html { redirect_to @coach, notice: 'Entrenador actualizado.' }
				format.json { render :show, status: :ok, location: @coach }
			else
				format.html { render :edit }
				format.json { render json: @coach.errors, status: :unprocessable_entity }
			end
		end
	end

 	# DELETE /coaches/1
	# DELETE /coaches/1.json
	def destroy
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
			format.html { redirect_to @coach, notice: 'Entrenador Creado.' }
			format.json { render :show, status: :created, location: @coach }
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
		params.require(:coach).permit(:id, :active, :avatar, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday])
	end
end
