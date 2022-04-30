class PlayersController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_player, only: [:show, :edit, :update, :destroy]

	# GET /players
	# GET /players.json
	def index
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@players = get_players
			respond_to do |format|
				format.xlsx {
					response.headers['Content-Disposition'] = "attachment; filename=players.xlsx"
				}
				format.html { render :index }
			end
		else
			redirect_to "/"
		end
	end

	# GET /players/1
	# GET /players/1.json
	def show
		if current_user.present? and (current_user.admin? or current_user.is_coach? or current_user.person.player_id==@player.id)
		else
			redirect_to "/"
		end
	end

	# GET /players/new
	def new
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@player = Player.new
			@player.build_person
		else
			redirect_to "/"
		end
	end

	# GET /players/1/edit
	def edit
		unless current_user.present? and (current_user.admin? or current_user.is_coach? or current_user.person.player_id==@player.id)
			redirect_to "/"
		end
	end

	# POST /players
	# POST /players.json
	def create
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			respond_to do |format|
				@player = rebuild_player(params)	# rebuild player
				if @player.is_duplicate? then
					format.html { redirect_to @player, notice: t(:player_duplicate) + "'#{@player.to_s}'" }
					format.json { render :show,  :created, location: @player }
				else
					@player.person.save
					@player.person_id = @player.person.id
					if @player.save
						if @player.person.player_id != @player.id
							@player.person.player_id = @player.id
							@player.person.save
						end
						format.html { redirect_to players_url, notice: t(:player_created) + "'#{@player.to_s}'" }
						format.json { render :index, status: :created, location: players_url }
					else
						format.html { render :new }
						format.json { render json: @player.errors, status: :unprocessable_entity }
					end
				end
			end
		else
			redirect_to "/"
		end
	end

	# PATCH/PUT /players/1
	# PATCH/PUT /players/1.json
	def update
		if current_user.present? and (current_user.admin? or current_user.is_coach? or current_user.person.player_id==@player.id)
			respond_to do |format|
				if @player.update(player_params)
					format.html { redirect_to players_url, notice: t(:player_updated) + "'#{@player.to_s}'" }
					format.json { render :index, status: :ok, location: players_url }
				else
					format.html { render :edit }
					format.json { render json: @player.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/"
		end
	end

  # GET /players/import
  # GET /players/import.json
	def import
		if current_user.present? and current_user.admin?
			# added to import excel
	    Player.import(params[:file])
	    format.html { redirect_to players_url, notice: t(:player_import) + "'#{params[:file]}'" }
		else
			redirect_to "/"
		end
	end

	# DELETE /players/1
	# DELETE /players/1.json
	def destroy
		if current_user.present? and current_user.admin?
			p_name = @player.to_s
			unlink_person
			@player.destroy
			respond_to do |format|
				format.html { redirect_to players_url, notice: t(:player_deleted) + "'#{p_name}'" }
				format.json { head :no_content }
			end
		else
			redirect_to "/"
		end
	end

	private
	# Use callbacks to share common setup or constraints between actions.
	def set_player
		@player = Player.find(params[:id]) unless @player.try(:id)==params[:id]
	end

	# get player list depending on the search parameter & user role
	def get_players
		if (params[:search] != nil) and (params[:search].length > 0)
			@players = Player.search(params[:search])
		else
			Player.none
		end
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def player_params
		params.require(:player).permit(:id, :number, :active, :avatar, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :female, :email, :phone, :player_id], teams_attributes: [:id, :_destroy])
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
		@player.person[:female] = p_data[:female]
		@player.person[:email] = p_data[:email]
		@player.person[:phone] = Phonelib.parse(p_data[:phone]).international.to_s
		@player.person[:coach_id] = 0
		@player.person[:player_id] = 0
		@player
	end

	# De-couple from associated person
	def unlink_person
		if @player.person.try(:player_id) == @player.id
			p = @player.person
			p.player=Player.find(0)   # map to empty player
			p.save
			@player.person_id = 0    # map to empty person
    end
	end
end
