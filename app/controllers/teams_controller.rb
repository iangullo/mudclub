class TeamsController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :edit, :new, :update, :check_reload]
	before_action :set_team, only: [:index, :show, :roster, :slots, :edit, :edit_roster, :edit_coaches, :targets, :edit_targets, :plan, :edit_plan, :new, :update, :destroy]

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
		unless current_user.present? and (current_user.admin? or current_user.is_coach? or @team.has_player(current_user.person.player_id))
			redirect_to "/"
		else
			redirect_to coaching_team_path(@team) if params[:id]=="coaching" and @team
		end
  end

	# GET /teams/1/roster
  def roster
		if current_user.present?
			unless current_user.admin? or current_user.is_coach? or @team.has_player(current_user.person.player_id)
				redirect_to @team
			end
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/slots
  def slots
		if current_user.present?
			unless current_user.admin? or current_user.is_coach?
				redirect_to @team
			end
		else
			redirect_to "/"
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
				@eligible_coaches = Coach.active
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

  # POST /teams
  # POST /teams.json
  def create
		if current_user.present? and current_user.admin?
		  @team = Team.new(team_params)

	    respond_to do |format|
	      if @team.save
	        format.html { redirect_to teams_path, notice: "Equipo '#{@team.to_s}' creado." }
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

	# GET /teams/1/targets
  def targets
		if current_user.present? and current_user.is_coach?
			redirect_to "/" unless @team
			global_targets(true)	# get & breakdown global targets
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/edit_targets
  def edit_targets
		if current_user.present? and @team.has_coach(current_user.person.coach_id)
			redirect_to "/" unless @team
			global_targets(false)	# get global targets
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/edit_targets
  def plan
		if current_user.present? and current_user.is_coach?
			redirect_to "/" unless @team
			plan_targets(params[:month] ? params[:month].to_i : Date.today.month)
		else
			redirect_to "/"
		end
  end

	# GET /teams/1/edit_plan
  def edit_plan
		if current_user.present? and @team.has_coach(current_user.person.coach_id)
			redirect_to "/" unless @team
			plan_targets(nil)
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
						format.html { redirect_to @team, notice: "Equipo '#{@team.to_s}' actualizado." }
		        format.json { render :show, status: :created, location: teams_path(@team) }
		      else
		        format.html { render :edit }
		        format.json { render json: @team.errors, status: :unprocessable_entity }
		      end
		    end
			else
				redirect_to(current_user.is_coach? ? @team : "/")
			end
		else
			redirect_to "/"
		end
  end

  # DELETE /teams/1
  # DELETE /teams/1.json
  def destroy
		if current_user.present? and current_user.admin?
			t_name = @team.to_s
			erase_links
	    @team.destroy
	    respond_to do |format|
	      format.html { redirect_to teams_path, notice: "Equipo '#{t_name}' borrado." }
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

	# retrieve targets for the team
	def global_targets(breakdown=false)
    targets = @team.team_targets.global
		if breakdown
	    @t_d_gen = filter(targets, 0, 2)
	    @t_d_ind = filter(targets, 1, 2)
	    @t_d_col = filter(targets, 2, 2)
	    @t_o_gen = filter(targets, 0, 1)
	    @t_o_ind = filter(targets, 1, 1)
	    @t_o_col = filter(targets, 2, 1)
		end
  end

	# retrieve monthly targets for the team
	def plan_targets(month)
		@months = @team.season.months(true)
		@targets = Array.new
		if month	# we are searching in a specific month
			@targets << fetch_targets(month)
		else
			@months.each { |m| @targets << fetch_targets(m)	}
		end
  end

	# get team targets for a specific month
	def fetch_targets(month)
		case month
		when Integer
			tgt = @team.team_targets.monthly(month)
			m   = {i: month, name: Date::ABBR_MONTHNAMES[month]}
		when Array
			tgt = @team.team_targets.monthly(month[1])
			m   = {i: month[1], name: Date::ABBR_MONTHNAMES[month[1]]}
		else
			tgt = @team.team_targets.monthly(month[:i])
			m   = {i: month[:i], name: month[:name]}
		end
		t_d_ind = filter(tgt, 1, 2)
		t_o_ind = filter(tgt, 1, 1)
		t_d_col = filter(tgt, 2, 2)
		t_o_col = filter(tgt, 2, 1)
		{i: m[:i], month: m[:name], t_d_ind: t_d_ind, t_o_ind: t_o_ind, t_d_col: t_d_col, t_o_col: t_o_col}
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
		check_players(p_data[:player_ids]) if p_data[:player_ids]
		check_coaches(p_data[:coach_ids]) if p_data[:coach_ids]
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

	# ensure we get the right players
	def check_players(p_array)
		# first pass
		a_targets = Array.new	# array to include all targets
		p_array.each { |t| a_targets << Player.find(t.to_i) unless t.to_i==0 }

		# second pass - manage associations
		a_targets.each { |t| @team.players << t unless @team.has_player(t.id)	}

		# cleanup roster
		@team.players.each { |p| @team.players.delete(p) unless a_targets.include?(p) }
	end

	# ensure we get the right players
	def check_coaches(c_array)
		# first pass
		a_targets = Array.new	# array to include all targets
		c_array.each { |t| a_targets << Coach.find(t.to_i) unless t.to_i==0 }

		# second pass - manage associations
		a_targets.each { |t| @team.coaches << t unless @team.has_coach(t.id) }

		# cleanup roster
		@team.coaches.each { |c| @team.coaches.delete(c) unless a_targets.include?(c) }
	end

	# remove dependent records prior to deleting
	def erase_links
		@team.slots.each { |slot| slot.delete }	# training slots
		@team.targets.each { |tgt| tgt.delete }	# team targets & coaching plan
		@team.events.each { |event|							# associated events
			event.tasks.each { |task| task.delete }
			event.match.delete if event.match
			event.delete
		}
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def team_params
		params.require(:team).permit(:id, :name, :category_id, :division_id, :season_id, :homecourt_id, :coaches, :players, :targets, :team_targets, coaches_attributes: [:id], coach_ids: [], player_ids: [], players_attributes: [:id], targets_attributes: [], team_targets_attributes: [])
	end
end
