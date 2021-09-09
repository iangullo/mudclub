class PlayersController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_player, only: [:show, :edit, :update, :destroy]

	# GET /players
	# GET /players.json
	def index
		@players = Player.search(params[:search])

		respond_to do |format|
			format.xlsx {
				response.headers['Content-Disposition'] = "attachment; filename='players.xlsx'"
			}
			format.html { render :index }
		end
	end

	# GET /players/1
	# GET /players/1.json
	def show
	end

	# GET /players/new
	def new
		@player = Player.new
		@player.build_person
	end

	# GET /players/1/edit
	def edit
	end

	# POST /players
	# POST /players.json
	def create
		respond_to do |format|
			@player = rebuild_player(params)	# rebuild player
			if @player.is_duplicate? then
				format.html { redirect_to @player, notice: 'Ya existía este jugador.'}
				format.json { render :show,  :created, location: @player }
			else
				if @player.save
					if @player.person.player_id != @player.id
						@player.person.player_id = @player.id
						@player.person.save
					end
					format.html { redirect_to players_url, notice: 'Jugador creado.' }
					format.json { render :index, status: :created, location: players_url }
				else
					format.html { render :new }
					format.json { render json: @player.errors, status: :unprocessable_entity }
				end
			end
		end
	end

	# PATCH/PUT /players/1
	# PATCH/PUT /players/1.json
	def update
		respond_to do |format|

			if @player.update(player_params)
				format.html { redirect_to players_url, notice: 'Jugador actualizado.' }
				format.json { render :index, status: :ok, location: players_url }
			else
				format.html { render :edit }
				format.json { render json: @player.errors, status: :unprocessable_entity }
			end
		end
	end


  # GET /players/import
  # GET /players/import.json
	def import
		# added to import excel
    Player.import(params[:file])
    redirect_to players_url
	end

	# DELETE /players/1
	# DELETE /players/1.json
	def destroy
		@player.destroy
		respond_to do |format|
			format.html { redirect_to players_url, notice: 'Jugador borrado.' }
			format.json { head :no_content }
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_player
			@player = Player.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def player_params
			params.require(:player).permit(:id, :number, :active, :avatar, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :female, :player_id], teams_attributes: [:id, :_destroy])
		end

	# build new @player from raw input given by submittal from "new"
	# return nil if unsuccessful
	def rebuild_player(params)
		@player = Player.new(player_params)
		@player.build_person
		@player.active = true
		@player.number = params.fetch(:player)[:number]
		p_data= params.fetch(:player).fetch(:person_attributes)
		@player.person[:dni] = p_data[:dni]
		@player.person[:nick] = p_data[:nick]
		@player.person[:name] = p_data[:name]
		@player.person[:surname] = p_data[:surname]
		@player.person[:coach_id] = 0
		@player.person[:player_id] = 0
		@player
	end
end
