class TeamsController < ApplicationController
	include Filterable
	skip_before_action :verify_authenticity_token, :only => [:create, :edit, :new, :update, :check_reload]
	before_action :set_team, only: [:index, :show, :roster, :slots, :edit, :edit_roster, :attendance, :targets, :edit_targets, :plan, :edit_plan, :new, :update, :destroy]

  # GET /teams
  # GET /teams.json
  def index
		if current_user.present? and (current_user.admin? or current_user.is_coach? or current_user.is_player?)
			@title = title_fields(I18n.t(:l_team_index), search: true)
			@grid  = team_grid
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

  # GET /teams/new
  def new
		if current_user.present? and current_user.admin?
    	@team = Team.new(season_id: params[:season_id] ? params[:season_id] : Season.last.id)
			@eligible_coaches = Coach.active
			@form_fields      = form_fields(I18n.t(:l_team_new))
		else
			redirect_to(current_user.is_coach? ? teams_path : "/", data: {turbo_action: "replace"})
		end
  end

  # GET /teams/1
  # GET /teams/1.json
  def show
		unless current_user.present? and (current_user.admin? or current_user.is_coach? or @team.has_player(current_user.person.player_id))
			redirect_to "/", data: {turbo_action: "replace"}
		else
			redirect_to coaching_team_path(@team) if params[:id]=="coaching" and @team
			@title = title_fields(@team.to_s)
			@links = team_links
			@grid  = event_grid(events: @team.events.upcoming.order(:start_time), obj: @team)
		end
  end

	# GET /teams/1/roster
  def roster
		if current_user.present?
			unless current_user.admin? or current_user.is_coach? or @team.has_player(current_user.person.player_id)
				redirect_to @team
			end
			@title = title_fields(@team.to_s)
			@title << [{kind: "icon", value: "player.svg", size: "30x30"}, {kind: "label", value: I18n.t(:l_roster_show)}]
			@grid  = player_grid(players: @team.players.order(:number), obj: @team)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

	# GET /teams/1/edit_roster
  def edit_roster
		if current_user.present?
			if current_user.admin? or @team.has_coach(current_user.person.coach_id)
				@title = title_fields(@team.to_s)
				@title << [{kind: "icon", value: "player.svg", size: "30x30"}, {kind: "label", value: I18n.t(:l_roster_edit)}]
				@eligible_players = @team.eligible_players
			else
				redirect_to @team, data: {turbo_action: "replace"}
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

	# GET /teams/1/slots
  def slots
		if current_user.present?
			unless current_user.admin? or current_user.is_coach?
				redirect_to @team
			end
			@title = title_fields(@team.to_s)
			@title << [{kind: "icon", value: "timetable.svg", size: "30x30"}, {kind: "label", value: I18n.t(:l_slot_index)}]
	else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

	# GET /teams/1/targets
  def targets
		if current_user.admin? or current_user.is_coach?
			redirect_to "/" unless @team
			global_targets(true)	# get & breakdown global targets
			@title = title_fields(@team.to_s)
			@title << [{kind: "icon", value: "target.svg", size: "30x30"}, {kind: "label", value: I18n.t(:h_targ)}]
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

	# GET /teams/1/edit_targets
  def edit_targets
		if current_user.present? and @team.has_coach(current_user.person.coach_id)
			redirect_to("/", data: {turbo_action: "replace"}) unless @team
			global_targets(false)	# get global targets
			@title = title_fields(@team.to_s)
			@title << [{kind: "icon", value: "target.svg", size: "30x30"}, {kind: "label", value: I18n.t(:l_targ_edit)}]
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

	# GET /teams/1/edit_targets
  def plan
		if current_user.admin? or current_user.is_coach?
			redirect_to "/" unless @team
			plan_targets
			@title = title_fields(@team.to_s)
			@title << [{kind: "icon", value: "teamplan.svg", size: "30x30"}, {kind: "label", value: I18n.t(:l_plan_show)}]
			@edit = edit_plan_team_path if @team.has_coach(current_user.person.coach_id)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

	# GET /teams/1/edit_plan
  def edit_plan
		if current_user.present? and @team.has_coach(current_user.person.coach_id)
			redirect_to("/", data: {turbo_action: "replace"}) unless @team
			plan_targets
			@title  = title_fields(@team.to_s)
			@title << [{kind: "icon", value: "teamplan.svg", size: "30x30"}, {kind: "label", value: I18n.t(:l_plan_edit)}]
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

	# GET /teams/1/attendance
  def attendance
		if current_user.present?
			unless current_user.admin? or current_user.is_coach? or @team.has_player(current_user.person.player_id)
				redirect_to @team
			end
			@title = title_fields(@team.to_s)
			@title << [{kind: "icon", value: "attendance.svg", size: "30x30"}, {kind: "label", value: I18n.t(:l_attendance)}]
			@grid  = attendance_grid
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

  # GET /teams/1/edit
  def edit
		if current_user.present?
			if current_user.admin? or @team.has_coach(current_user.person.coach_id)
				@eligible_coaches = Coach.active
				@form_fields      = form_fields(I18n.t(:l_team_edit))
			else
				redirect_to @team
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

  # POST /teams
  # POST /teams.json
  def create
		if current_user.present? and current_user.admin?
		  @team = Team.new(team_params)

	    respond_to do |format|
	      if @team.save
	        format.html { redirect_to teams_path, notice: {kind: "success", message: "#{I18n.t(:team_created)} '#{@team.to_s}'"}, data: {turbo_action: "replace"} }
	        format.json { render :index, status: :created, location: teams_path }
	      else
	        format.html { render :new }
	        format.json { render json: @team.errors, status: :unprocessable_entity }
	      end
	    end
		else
			redirect_to(current_user.is_coach? ? teams_path : "/", data: {turbo_action: "replace"})
		end
  end

  # PATCH/PUT /teams/1
  # PATCH/PUT /teams/1.json
  def update
		if current_user.present?
			if current_user.admin? or @team.has_coach(current_user.person.coach_id)
		    respond_to do |format|
					if params[:team]
						retlnk = params[:team][:retlnk]
						rebuild_team
		      	if @team.save
							format.html { redirect_to retlnk, notice: {kind: "success", message: "#{I18n.t(:team_updated)} '#{@team.to_s}'"}, data: {turbo_action: "replace"} }
							format.json { redirect_to retlnk, status: :created, location: retlnk }
						else
							@eligible_coaches = Coach.active
							@form_fields      = form_fields(I18n.t(:l_team_edit))
							format.html { render :edit, data:{"turbo-frame": "replace"}, notice: {kind: "error", message: "#{I18n.t(:i_no_data)} (#{@team.to_s})"} }
							format.json { render json: @team.errors, status: :unprocessable_entity }
						end
					else	# no data to save...
		        format.html { redirect_to @team, data:{"turbo-frame": "replace"}, notice: {kind: "info", message: "#{I18n.t(:i_no_data)} (#{@team.to_s})"}, data: {turbo_action: "replace"} }
		        format.json { render json: @team.errors, status: :unprocessable_entity }
		      end
		    end
			else
				redirect_to(current_user.is_coach? ? @team : "/", data: {turbo_action: "replace"})
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
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
	      format.html { redirect_to teams_path, status: :see_other, notice: {kind: "success", message: "#{I18n.t(:team_deleted)} '#{t_name}'"}, data: {turbo_action: "replace"} }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

  private

    # return icon and top of HeaderComponent
  	def title_fields(title, cols: nil, search: nil, edit: nil)
			res = title_start(icon: "team.svg", title: title, cols: cols)
			if search
				res << [{kind: "search-collection", key: :season_id, options: Season.real.order(start_date: :desc), value: @team ? @team.season_id : session.dig('team_filters', 'season_id')}]
			elsif edit and current_user.admin?
				res << [{kind: "select-collection", key: :season_id, options: Season.real, value: @team.season_id}]
			else
				res << [{kind: "label", value: @team.season.name}]
			end
			res
  	end

	  # return HeaderComponent @fields for forms
	  def form_fields(title, cols: nil)
			res = title_fields(title, cols: cols, edit: true)
			res << [{kind: "label", align: "right", value: I18n.t(:l_name)}, {kind: "text-box", key: :name, value: @team.name}]
	    res << [{kind: "icon", value: "category.svg"}, {kind: "select-collection", key: :category_id, options: Category.real, value: @team.category_id}]
			res << [{kind: "icon", value: "division.svg"}, {kind: "select-collection", key: :division_id, options: Division.real, value: @team.division_id}]
			res << [{kind: "icon", value: "location.svg"}, {kind: "select-collection", key: :homecourt_id, options: Location.home, value: @team.homecourt_id}]
			res << [{kind: "icon", value: "coach.svg"}, {kind: "label", value:I18n.t(:l_coach_index), class: "align-center"}]
			res << [{kind: "gap"}, {kind: "select-checkboxes", key: :coach_ids, options: @eligible_coaches}]
	  	res
		end

		# return grid for @teams GridComponent
    def team_grid
      title = [{kind: "normal", value: I18n.t(:h_name)}]
			title << {kind: "normal", value: I18n.t(:l_sea_show)} unless (params[:season_id] and params[:season_id].to_i>0)
      title << {kind: "normal", value: I18n.t(:l_div_show)}
			title << {kind: "add", url: new_team_path, frame: "modal"} if current_user.admin?

      rows = Array.new
      @teams.each { |team|
        row = {url: team_path(team), items: []}
        row[:items] << {kind: "normal", value: team.to_s}
        row[:items] << {kind: "normal", value: team.season.name, align: "center"} unless (params[:season_id] and params[:season_id].to_i>0)
        row[:items] << {kind: "normal", value: team.division.name, align: "center"}
        row[:items] << {kind: "delete", url: row[:url], name: team.to_s} if current_user.admin?
        rows << row
      }
			{title: title, rows: rows}
    end

		# return jump links for a team
		def team_links
			res = [[{kind: "jump", icon: "player.svg", url: roster_team_path(@team), label: I18n.t(:l_roster_show), frame: "modal", align: "center"}]]
			if (current_user.admin? or current_user.is_coach?)
				res.last << {kind: "jump", icon: "target.svg", url: targets_team_path(@team), label: I18n.t(:h_targ), align: "center"}
        res.last << {kind: "jump", icon: "teamplan.svg", url: plan_team_path(@team), label: I18n.t(:a_plan), align: "center"}
			end
			res.last << {kind: "jump", icon: "timetable.svg", url: slots_team_path(@team), label: I18n.t(:l_slot_index), frame: "modal", align: "center"}
			if (current_user.admin? or @team.has_coach(current_user.person.coach_id))
	      res.last << {kind: "edit", url: edit_team_path, size: "30x30", frame: "modal"}
			end
			res << [{kind: "gap"}]
			res
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
		def plan_targets
			@months = @team.season.months(true)
			@targets = Array.new
			@months.each { |m| @targets << fetch_targets(m)	}
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
				#event.match.delete if event.match
				event.delete
			}
		end

  # A Field Component with grid for team attendance. obj is the parent oject (player/team)
  def attendance_grid
		title = [{kind: "normal", value: I18n.t(:a_num), align: "center"}, {kind: "normal", value: I18n.t(:h_name)}, {kind: "normal", value: I18n.t("stat.total"), align: "center"}, {kind: "normal", value: I18n.t("train.many"), align: "center"}, {kind: "normal", value: I18n.t("match.many"), align: "center"}]
    rows = Array.new
    @team.players.order(:number).each { |player|
			p_att = player.attendance(team: @team)
      row   = {items: []}
      row[:items] << {kind: "normal", value: player.number, align: "center"}
      row[:items] << {kind: "normal", value: player.to_s}
      row[:items] << {kind: "percentage", value: p_att[:avg], align: "right"}
      row[:items] << {kind: "percentage", value: p_att[:sessions], align: "right"}
      row[:items] << {kind: "percentage", value: p_att[:matches], align: "right"}
      rows << row
    }
		t_att     = @team.attendance
		@att_data = [t_att[:sessions], t_att[:matches]]
		rows << {items: [{kind: "bottom", value: nil}, {kind: "bottom", align: "right", value: I18n.t("stat.average")}, {kind: "percentage", value: t_att[:total][:avg], align: "right"}, {kind: "percentage", value: t_att[:sessions][:avg], align: "right"}, {kind: "percentage", value: t_att[:matches][:avg], align: "right"}]}
    return {title: title, rows: rows}
	end

		# Use callbacks to share common setup or constraints between actions.
		def set_team
			@teams = Team.search(params[:season_id] ? params[:season_id] : session.dig('team_filters', 'season_id'))
			if params[:id]=="coaching"
				@team = current_user.coach.teams.first
			else
				@team = Team.find(params[:id]) if params[:id]
			end
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def team_params
			params.require(:team).permit(:id, :name, :category_id, :division_id, :season_id, :homecourt_id, :coaches, :players, :targets, :team_targets, coaches_attributes: [:id], coach_ids: [], player_ids: [], players_attributes: [:id], targets_attributes: [], team_targets_attributes: [])
		end
end
