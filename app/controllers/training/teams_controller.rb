# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
# Managament of MudClub teams - belonging to a club
class TeamsController < ApplicationController
  include Filterable
  before_action :set_team_context, only: [ :index, :show, :roster, :slots, :edit, :edit_roster, :attendance, :targets, :edit_targets, :plan, :edit_plan, :new, :update, :destroy ]

  # GET /club/x/teams
  # GET /club/x/teams.json
  def index
    @team_policy = check_policy!(TeamPolicy, club: @club)

    @teams = Team.for_club(@club&.id).for_season(@season&.id).ordered
    respond_to do |format|
      format.xlsx do
        f_name = "#{@season.name(safe: true)}-athletes.xlsx"
        a_desc = "#{I18n.t("player.export")} '#{f_name}'"
        register_action(:exported, a_desc, url: club_teams_path(rdx: 2))
        response.headers["Content-Disposition"] = "attachment; filename=#{f_name}"
      end
      format.html do
        title   = helpers.team_title(title: Team.label(:plural), search: true)
        page    = paginate(@teams)	# paginate results
        table   = helpers.team_table(teams: page)
        zerolnk = @club ? club_path(@club, rdx: @rdx) : (u_admin? ? clubs_path(rdx: @rdx) : "/")
        retlnk  = base_lnk(zerolnk)
        submit  = { kind: :export, url: club_teams_path(@club, format: :xlsx, season_id: @season.id), working: false } if user_in_club? && (u_manager? || u_secretary?)
        create_index(title:, table:, page:, retlnk:, submit:)
        render :index
      end
    end
  end

  # GET /club/x/teams/1
  # GET /club/x/teams/1.json
  def show
    @team_policy = check_policy!(TeamPolicy, record: @team)

    @sport   = @team.sport.specific
    title    = helpers.team_title(title: @team.nick)
    w_l = @team.win_loss
    if w_l[:won] > 0 || w_l[:lost] > 0
      wlstr = "(#{w_l[:won]}#{I18n.t("match.won")} - #{w_l[:lost]}#{I18n.t("match.lost")})"
      title << [ helpers.gap_field, { kind: :text, value: wlstr } ]
    end
    @title   = create_fields(title)
    @coaches = create_fields(helpers.team_coaches)
    if u_manager? || u_coach?
      @links = create_fields(helpers.team_links)
      @table = create_fields(helpers.event_list_table(obj: @team))
      submit = edit_club_team_path(@club, @team, rdx: @rdx) if @team_policy.edit?
    else
      start_date = (params[:start_date] ? params[:start_date] : Date.today.at_beginning_of_month).to_date
      anchor     = { url: club_team_events_path(@club, @team), rdx: @rdx }
      @calendar  = CalendarComponent.new(anchor:, start_date:, obj: @team, user: current_user)
      submit     = nil
    end
    zerolnk = club_teams_path(@club, season_id: @season&.id, rdx: @rdx)
    @submit = create_submit(close: :back, retlnk: base_lnk(zerolnk), submit:, frame: (submit ? "modal" : nil))
  end

  # GET /club/x/teams/new - can only be called from a teams index
  def new
    @team_policy = check_policy!(TeamPolicy, club: @club)

    @eligible_coaches = @club.coaches
    @team   = Team.new(club: @club, sport_id: @club.sports.first&.id, nick: @club.nick, season_id: (params[:season_id].presence&.to_i || Season.latest.id))
    @fields = create_fields(helpers.team_form(title: I18n.t("team.new")))
    @submit = create_submit(retlnk: club_teams_path(@club, rdx: 0))
  end

  # GET /club/x/teams/1/edit
  def edit
    @team_policy = check_policy!(TeamPolicy, record: @team)

    @eligible_coaches = @club.coaches
    @sport  = @team.sport.specific
    @fields = create_fields(helpers.team_form(title: I18n.t("team.edit")))
    @submit = create_submit
  end

  # POST /club/x/teams
  # POST /club/x/teams.json
  def create
    @team_policy = check_policy!(TeamPolicy, club: @club)

    respond_to do |format|
      retlnk = cru_return
      if team_params
        @team = Team.build(team_params)
        if @team.save
          a_desc = "#{Team.msg(:created)} '#{@team}'"
          c_path = (user_in_club? ? retlnk : club_teams_path(@club, rdx: @rdx))
          register_action(:created, a_desc, url: club_team_path(@club, @team, rdx: 2))
          format.html { redirect_to c_path, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
          format.json { render :index, status: :created, location: c_path }
        else
          @eligible_coaches = Coach.active
          @fields = create_fields(helpers.team_form(title: I18n.t("team.new")))
          @submit = create_submit
          format.html { render :new }
          format.json { render json: @team.errors, status: :unprocessable_entity }
        end
      else	# no data to save...
        format.html { redirect_to retlnk, notice: n_notice, data: { turbo_action: "replace" } }
        format.json { redirect_to retlnk, status: :ok, location: retlnk }
      end
    end
  end

  # PATCH/PUT /club/x/teams/1
  # PATCH/PUT /club/x/teams/1.json
  def update
    @team_policy = check_policy!(TeamPolicy, record: @team)

    respond_to do |format|
      n_notice = no_data_notice(trail: @team.to_s)
      retlnk   = cru_return
      if team_params
        @team.rebuild(team_params)
        if @team.modified?
          if @team.save
            a_desc = "#{Team.msg(:updated)} '#{@team}'"
            register_action(:updated, a_desc, url: club_team_path(@club, @team, rdx: 2))
            format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
            format.json { redirect_to retlnk, status: :created, location: retlnk }
          else
            @eligible_coaches = Coach.active
            @fields = create_fields(helpers.team_form(title: I18n.t("team.edit")))
            @submit = create_submit
            format.html { render :edit, data: { "turbo-frame": "replace" }, notice: helpers.flash_message(@team.errors, "error") }
            format.json { render json: @team.errors, status: :unprocessable_entity }
          end
        else	# no data to save...
          format.html { redirect_to retlnk, notice: n_notice, data: { turbo_action: "replace" } }
          format.json { render json: @team.errors, status: :unprocessable_entity }
        end
      else	# no data to save...
        format.html { redirect_to retlnk, notice: n_notice, data: { turbo_action: "replace" } }
        format.json { redirect_to retlnk, status: :ok, location: retlnk }
      end
    end
  end

  # DELETE /club/x/teams/1
  # DELETE /club/x/teams/1.json
  def destroy
    # cannot destroy placeholder teams (id: 0 || -1)
    @team_policy = check_policy!(TeamPolicy, record: @team)
    t_name = @team.to_s
    @team.destroy
    respond_to do |format|
      a_desc = "#{Team.msg(:deleted)} '#{t_name}'"
      register_action(:deleted, a_desc)
      format.html { redirect_to club_teams_path(@club, rdx: @rdx), status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
      format.json { head :no_content }
    end
  end

  # GET /club/x/teams/1/roster
  def roster
    @team_policy = check_policy!(TeamPolicy, record: @team)

    title = helpers.team_title(title: @team.nick)
    title << icon_subtitle(:player, Team.term(:roster), namespace: @team.sport.name)

    @athletes = @team.athletes.by_number
    title.last << { kind: :string, value: "(#{@athletes.count} #{@team.term(:athlete, :short)})" }
    @title  = create_fields(title)

    @table  = create_table(helpers.team_roster_table(@athletes))

    submit  = club_team_edit_roster_path(@club, @team, rdx: @rdx) if @team_policy.edit_roster?
    @submit = create_submit(close: :back, retlnk: club_team_path(@club, @team, rdx: @rdx), submit:)
  end

  # GET /club/x/teams/1/edit_roster
  def edit_roster
    @team_policy = check_policy!(TeamPolicy, record: @team)

    title = helpers.team_title(title: @team.to_s)
    title << icon_subtitle("player", I18n.t("team.roster_edit"), namespace: @team.sport.name)
    @title  = create_fields(title)
    @submit = create_submit(close: :cancel, retlnk: club_team_roster_path(@club, @team, rdx: @rdx))
    @eligible_athletes = @team.eligible_athletes
  end

  # GET /club/x/teams/1/slots
  def slots
    @team_policy = check_policy!(TeamPolicy, record: @team)

    title   = helpers.team_title(title: @team.to_s)
    @title   = create_fields(title)
    @fields = create_fields(helpers.team_slots) unless @team.slots.empty?
  end

  # GET /club/x/teams/1/targets
  def targets
    @team_policy = check_policy!(TeamPolicy, record: @team)

    global_targets(true)	# get & breakdown global targets
    title   = helpers.team_title(title: @team.to_s)
    title  << icon_subtitle("target", Target.label(:plural))
    @title  = create_fields(title)
    edit    = club_team_edit_targets_path(@club, @team, rdx: @rdx) if @team_policy.edit_targets?
    @fields = create_fields(helpers.team_targets_show)
    @submit = create_submit(close: :back, retlnk: club_team_path(@club, @team, rdx: @rdx), submit: edit)
  end

  # GET /club/x/teams/1/edit_targets
  def edit_targets
    @team_policy = check_policy!(TeamPolicy, record: @team)

    global_targets(true)	# get global targets
    title   = helpers.team_title(title: @team.to_s)
    title << icon_subtitle("target", Target.act(:edit))
    @title  = create_fields(title)
    @submit = create_submit(close: :cancel, retlnk: club_team_targets_path(@club, @team, rdx: @rdx))
  end

  # GET /club/x/teams/1/edit_targets
  def plan
    @team_policy = check_policy!(TeamPolicy, record: @team)

    plan_targets
    title = helpers.team_title(title: @team.to_s)
    title << icon_subtitle("plan", I18n.t("training.plan.label"))
    @title = create_fields(title)
    edit    = club_team_edit_plan_path(@club, @team, rdx: @rdx) if team_manager?
    @fields = create_fields(helpers.team_plan_accordion)
    @submit = create_submit(close: :back, retlnk: club_team_path(@club, @team, rdx: @rdx), submit: edit)
  end

  # GET /club/x/teams/1/edit_plan
  def edit_plan
    @team_policy = check_policy!(TeamPolicy, record: @team)

    redirect_to("/", data: { turbo_action: "replace" }) unless @team
    plan_targets
    title   = helpers.team_title(title: @team.to_s)
    title << icon_subtitle("plan", I18n.t("plan.edit"))
    @title  = create_fields(title)
    @submit = create_submit(close: :cancel, retlnk: club_team_plan_path(@club, @team, rdx: @rdx))
  end

  # GET /club/x/teams/1/attendance
  def attendance
    @team_policy = check_policy!(TeamPolicy, record: @team)

    title  = helpers.team_title(title: @team.to_s)
    title  << icon_subtitle("attendance", I18n.t("calendar.attendance.label"))
    @title  = create_fields(title)
    a_data  = helpers.team_attendance_table
    if a_data
      @table = create_table({ title: a_data[:title], rows: a_data[:rows] })
      @att_data = [ a_data[:chart] ] if a_data
    end
    @submit = create_submit(submit: nil)
  end

  private
    # wrapper to set return link for create && update operations
    def cru_return
      if param_passed(:team, :player_ids)	# roster view
        club_team_roster_path(@club, @team, rdx: @rdx)
      elsif param_passed(:team, :team_targets_attributes)	# targets or plan
        first_target = team_params[:team_targets_attributes].to_h.first
        if first_target
          if first_target[1]["month"] == "0"	# global team targets
            club_team_targets_path(@club, @team, rdx: @rdx)
          else	# team monthly targets
            club_team_plan_path(@club, @team, rdx: @rdx)
          end
        else	# base team view
          club_team_path(@club, @team, rdx: @rdx)
        end
      else	# team view also
        club_team_path(@club, @team, rdx: @rdx)
      end
    end

    # get team targets for a specific month
    def fetch_targets(month)
      case month
      when Integer
        tgt = @team.team_targets.monthly(month)
        m   = { i: month, name: I18n.t("calendar.monthnames_a")[month] }
      when Array
        tgt = @team.team_targets.monthly(month[1])
        m   = { i: month[1], name: I18n.t("calendar.monthnames_a")[month[1]] }
      else
        tgt = @team.team_targets.monthly(month[:i])
        m   = { i: month[:i], name: month[:name] }
      end
      t_d_ind = filter(tgt, 1, 2)
      t_o_ind = filter(tgt, 1, 1)
      t_d_col = filter(tgt, 2, 2)
      t_o_col = filter(tgt, 2, 1)
      { i: m[:i], month: m[:name], t_d_ind: t_d_ind, t_o_ind: t_o_ind, t_d_col: t_d_col, t_o_col: t_o_col }
    end

    # filters a set of TeamTargets by aspect & focus of the associated targets
    def filter(tgts, aspect, focus)
      res = Array.new
      tgts.each { |tgt|
        res << tgt if (tgt.target.aspect_before_type_cast == aspect) and (tgt.target.focus_before_type_cast == focus)
      }
      res
    end

    # retrieve targets for the team
    def global_targets(breakdown = false)
      targets = @team.team_targets.global
      if breakdown
        @t_d_gen = { i: 0, aspect: 0, focus: 2, tgts: filter(targets, 0, 2) }
        @t_d_ind = { i: 0, aspect: 1, focus: 2, tgts: filter(targets, 1, 2) }
        @t_d_col = { i: 0, aspect: 2, focus: 2, tgts: filter(targets, 2, 2) }
        @t_o_gen = { i: 0, aspect: 0, focus: 1, tgts: filter(targets, 0, 1) }
        @t_o_ind = { i: 0, aspect: 1, focus: 1, tgts: filter(targets, 1, 1) }
        @t_o_col = { i: 0, aspect: 2, focus: 1, tgts: filter(targets, 2, 1) }
      else
        @targets = targets
      end
    end

    # reused across different views
    def icon_subtitle(icon, label, namespace: "common")
      [
        helpers.symbol_field(icon, { namespace: }, size: "30x30", align: "right", css: "mr-1"),
        { kind: :side_cell, value: label, align: "left" }
      ]
    end

    # retrieve monthly targets for the team
    def plan_targets
      @months = @team.season.months(true)
      @targets = Array.new
      @months.each { |m| @targets << fetch_targets(m)	}
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_team_context
      if (t_id = (params[:id].presence || p_teamid))
        @team = Team.find_by_id(t_id)
        @club = @team&.club if @team
      end
      @club ||= Club.find(p_clubid) if p_clubid
      s_id    = @team&.season&.id || p_seasonid || session.dig("team_filters", "season_id")
      @season = Season.search(s_id) unless s_id == @season&.id
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def team_params
      params.require(:team).permit(
        :id,
        :name,
        :nick,
        :club_id,
        :sport_id,
        :season_id,
        :category_id,
        :division_id,
        :rules,
        :homecourt_id,
        :targets,
        :team_targets,
        :coaches,
        :athletes,
        :rdx,
        athlete_ids: [],
        coach_ids: [],
        targets_attributes: [],
        team_targets_attributes: {}
      )
    end
end
