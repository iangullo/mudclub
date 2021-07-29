class TeamsController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :edit, :new, :update, :check_reload]
	before_action :set_team, only: [:show, :edit, :update, :destroy]

  # GET /teams
  # GET /teams.json
  def index
	@teams = Team.real
  end

  # GET /teams/1
  # GET /teams/1.json
  def show
  end

  # GET /teams/new
  def new
    @team = Team.new
  end

  # GET /teams/1/edit
  def edit
    @eligible_players = @team.eligible_players
  end

  # POST /teams
  # POST /teams.json
  def create
    @team = Team.new(team_params)

    respond_to do |format|
      if @team.save
        format.html { redirect_to @team, notice: 'Equipo creado.' }
        format.json { render :show, status: :created, location: @team }
      else
        format.html { render :new }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /teams/1
  # PATCH/PUT /teams/1.json
  def update
    respond_to do |format|
      if @team.update(team_params)
        format.html { redirect_to @team, notice: 'Equipo actualizado.' }
        format.json { render :show, status: :ok, location: @team }
      else
        format.html { render :edit }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /teams/1
  # DELETE /teams/1.json
  def destroy
    @team.destroy
    respond_to do |format|
      format.html { redirect_to teams_url, notice: 'Equipo borrado.' }
      format.json { head :no_content }
    end
  end

  private
	# Use callbacks to share common setup or constraints between actions.
	def set_team
		@team = Team.find(params[:id])
	end
	
	# Never trust parameters from the scary internet, only allow the white list through.
	def team_params
		params.require(:team).permit(:id, :name, :category_id, :division_id, :season_id, :coaches, :players, coaches_attributes: [:id], coach_ids: [], player_ids: [], players_attributes: [:id])
	end
end
