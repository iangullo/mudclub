class TeamsController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :edit, :new, :update, :check_reload]
	before_action :set_team, only: [:index, :show, :edit, :edit_roster, :edit_coaches, :coaching, :targets, :edit_targets, :plan, :edit_plan, :new, :update, :destroy]

  # GET /teams
  # GET /teams.json
  def index
		if current_user.present? and (current_user.admin? or current_user.is_coach? or current_user.is_player?)
		else
			redirect_to "/"
		end
  end

  # GET /teams/1
  # GET /teams/1.json
  def show
		unless current_user.present? and (current_user.admin? or current_user.is_coach? or @team.has_coach(current_user.person.coach_id) or @team.has_player(current_user.person.player_id))
			redirect_to "/"
		else
			redirect_to coaching_team_path(@team) if params[:id]=="coaching" and @team
		end
  end

  # GET /teams/new
  def new
		if current_user.present? and current_user.admin?
    	@team = Team.new
		else
			redirect_to(current_user.is_coach? ? teams_path : "/")
		end
  end

  # GET /teams/1/edit
  def edit
		if current_user.present?
			if current_user.admin? or @team.has_coach(current_user.person.coach_id)
			else
				redirect_to @team
			end
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/edit_roster
  def edit_roster
		if current_user.present?
			if current_user.admin? or @team.has_coach(current_user.person.coach_id)
    		@eligible_players = @team.eligible_players
			else
				redirect_to @team
			end
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/edit_coaches
  def edit_coaches
		if current_user.present?
			if current_user.admin? or @team.has_coach(current_user.person.coach_id)
    		@eligible_coaches = Coach.active
			else
				redirect_to @team
			end
		else
			redirect_to "/"
		end
  end

  # POST /teams
  # POST /teams.json
  def create
		if current_user.present? and current_user.admin?
		  @team = Team.new(team_params)

	    respond_to do |format|
	      if @team.save
	        format.html { redirect_to teams_path }
	        format.json { render :index, status: :created, location: teams_path }
	      else
	        format.html { render :new }
	        format.json { render json: @team.errors, status: :unprocessable_entity }
	      end
	    end
		else
			redirect_to(current_user.is_coach? ? teams_path : "/")
		end
  end

	# GET /teams/coaching or /teams/1/coaching
  def coaching
		if current_user.present? and current_user.is_coach?
			redirect_to "/" unless @team
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/targets
  def targets
		if current_user.present? and current_user.is_coach?
			redirect_to "/" unless @team
			breakdown_targets
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/targets
  def edit_targets
		if current_user.present? and current_user.is_coach?
			redirect_to "/" unless @team
			breakdown_targets
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/edit_targets
  def plan
		if current_user.present? and current_user.is_coach?
			breakdown_targets(true)
			redirect_to :home unless @team
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/edit_plan
  def edit_targets
		if current_user.present? and current_user.is_coach?
			redirect_to "/" unless @team
		else
			redirect_to "/"
		end
  end

  # PATCH/PUT /teams/1
  # PATCH/PUT /teams/1.json
  def update
		if current_user.present?
			if current_user.admin? or @team.has_coach(current_user.person.coach_id)
		    respond_to do |format|
					rebuild_team
		      if @team.save
						if params[:team][:team_targets_attributes]
							format.html { redirect_to coaching_team_path(@team) }
			        format.json { render :coaching, status: :created, location: teams_path(@team) }
						else
							format.html { redirect_to @team }
			        format.json { render :show, status: :created, location: teams_path(@team) }
						end
		      else
		        format.html { render :edit }
		        format.json { render json: @team.errors, status: :unprocessable_entity }
		      end
		    end
			else
				redirect_to(current_user.is_coach? ? teams_path : "/")
			end
		else
			redirect_to "/"
		end
  end

  # DELETE /teams/1
  # DELETE /teams/1.json
  def destroy
		if current_user.present? and current_user.admin?
	    @team.destroy
	    respond_to do |format|
	      format.html { redirect_to teams_path }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/"
		end
  end

  private
	# Use callbacks to share common setup or constraints between actions.
	def set_team
		@teams = Team.search(params[:season_id])
		if params[:id]=="coaching"
			@team = current_user.coach.teams.first
		else
			@team = Team.find(params[:id]) if params[:id]
		end
	end

	def breakdown_targets(plan=nil)
    targets = plan ? @team.team_targets.plan : @team.team_targets.global
    @t_d_gen = filter(targets, 0, 2)
    @t_d_ind = filter(targets, 1, 2)
    @t_d_col = filter(targets, 2, 2)
    @t_o_gen = filter(targets, 0, 1)
    @t_o_ind = filter(targets, 1, 1)
    @t_o_col = filter(targets, 2, 1)
  end

  # filters a set of TeamTargets by aspect & focus of the associated targets
  def filter(tgts,aspect,focus)
    res = Array.new
    tgts.each { |tgt|
      res << tgt if (tgt.target.aspect_before_type_cast == aspect) and (tgt.target.focus_before_type_cast == focus)
    }
    return res
  end

	def rebuild_team
		p_data = params.fetch(:team)
		@team.name         = p_data[:name] if p_data[:name]
		@team.season_id    = p_data[:season_id].to_i if p_data[:season_id]
		@team.category_id  = p_data[:category_id].to_i if p_data[:category_id]
		@team.division_id  = p_data[:division_id].to_i if p_data[:division_id]
		@team.homecourt_id = p_data[:homecourt_id].to_i if p_data[:homecourt_id]
		check_targets(p_data[:team_targets_attributes]) if p_data[:team_targets_attributes]
	end

	# ensure we get the right targets
	def check_targets(t_array)
		a_targets = Array.new	# array to include all targets
		t_array.each { |t| # first pass
			a_targets << t[1] # unless a_targets.detect { |a| a[:target_attributes][:concept] == t[1][:target_attributes][:concept] }
		}
		a_targets.each { |t| # second pass - manage associations
			if t[:_destroy] == "1"	# remove team_target
				TeamTarget.find(t[:id].to_i).delete
			else	# ensure creation of team_targets
				tt = TeamTarget.fetch(t)
				tt.save unless tt.persisted?
				@team.team_targets ? @team.team_targets << tt : @team.team_targets |= tt
			end
		}
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def team_params
		params.require(:team).permit(:id, :name, :category_id, :division_id, :season_id, :homecourt_id, :coaches, :players, :targets, :team_targets, coaches_attributes: [:id], coach_ids: [], player_ids: [], players_attributes: [:id], targets_attributes: [], team_targets_attributes: [])
	end
end
