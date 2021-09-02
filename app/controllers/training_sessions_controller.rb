class TrainingSessionsController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :edit, :new, :update, :check_reload]
	before_action :set_training_session, only: %i[ show edit update destroy ]

	# GET /training_sessions or /training_sessions.json
	def index
		@training_sessions = TrainingSession.search(params[:search])
	end

	# GET /training_sessions/1 or /training_sessions/1.json
	def show
	end

	# GET /training_sessions/new
	def new
		new_session(params[:team_id])
	end

	# GET /training_sessions/1/edit
	def edit
	end

	# POST /training_sessions or /training_sessions.json
	def create
		respond_to do |format|
			@training_session = TrainingSession.new
			rebuild_session(params)	# rebuild session
			if @training_session.save
				format.html { redirect_to @training_session, notice: "Sesión de entrenamiento creada." }
				format.json { render :show, status: :created, location: @training_session }
			else
				format.html { render :new, status: :unprocessable_entity }
				format.json { render json: @training_session.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /training_sessions/1 or /training_sessions/1.json
	def update
		respond_to do |format|
			set_date_time(training_session_params)
			if @training_session.update(training_session_params)
				format.html { redirect_to @training_session, notice: "Sesión actualizada." }
				format.json { render :show, status: :ok, location: @training_session }
			else
				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @training_session.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /training_sessions/1 or /training_sessions/1.json
	def destroy
		@training_session.destroy
		respond_to do |format|
			format.html { redirect_to training_sessions_url, notice: "Sesión borrada." }
			format.json { head :no_content }
		end
	end

	private
		def set_date_time(params)
			@training_session.set_date(params["date"])
			@training_session.hour = params["hour"]
			@training_session.min  = params["min"]
		end

		def new_session(team_id)
			@training_session = TrainingSession.new
			@training_session.team_id = team_id ? team_id : 0
			tslot = TrainingSlot.for_team(@training_session.team_id).first
			if tslot	# copy from trainingslot
				@training_session.training_slot_id= tslot.id
				@training_session.date= tslot.next_date
				@training_session.start= tslot.start
				@training_session.duration= tslot.duration
			else	# make them up
				@training_session.training_slot_id = 0
				@training_session.set_date(Date.today)
				@training_session.hour = 16
				@training_session.min = 00
				@training_session.duration = 90
			end
		end

		# build new @coach from raw input given by submittal from "new"
		# return nil if unsuccessful
		def rebuild_session(params)
			@training_session = TrainingSession.new(start: DateTime.now)
			p = params[:training_session]
			set_date_time(p)
			@training_session.team_id = p[:team_id]
			@training_session.targets = p[:targets]
			@training_session.location_id = p[:location_id]
			@training_session.duration = p[:duration]
			check_exercises(p[:exercises_attributes]) if p[:exercises_attributes]
		end

		# checks exercises parameter received and manage adding/removing
		# from the training_session
		def check_exercises(e_array)
			e_array.each { |e| # manage associations
				if e[:_destroy] == "1" and e.key?("id")
					@training_session.exercises.delete(e[:id])
					Exercise.find(e[:id]).delete
				else
					unless e.key?("id")	# if no id included, we create it
						ex = Exercise.create(training_session_id: @training_session.id, order: e[:order], drill_id: e[:drill_id], duration: e[:duration])
						@training_session.exercises << ex	# add to collection
					end
				end
			}
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_training_session
			@training_session = TrainingSession.find(params[:id])
		end

		# Only allow a list of trusted parameters through.
		def training_session_params
			params.require(:training_session).permit(:team_id, :date, :training_slot_id, :location_id, :start, :duration, :targets, exercise_ids: [], exercises_attributes: [])
		end
end
