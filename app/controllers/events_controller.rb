class EventsController < ApplicationController
  include Filterable
  before_action :set_event, only: %i[ show edit add_task show_task edit_task task_drill load_chart attendance update destroy ]

  # GET /events or /events.json
  def index
    check_access(roles: [:user])
    @events = Event.search(params)
    @team   = Team.find(params[:team_id]) if params[:team_id]
    @season = @events.empty? ? Season.last : @events.first.team.season
    @title  = helpers.event_index_title(team: @team, season: @season)
    if @team
      @grid = helpers.event_grid(events: @events, obj: @team, retlnk: team_events_path(@team))
    elsif @season
      @grid = helpers.event_grid(events: @events, obj: @season, retlnk: season_events_path(@season))
    else
      @grid = nil
    end
  end

  # GET /events/1 or /events/1.json
  def show
		check_access(roles: [:admin, :coach])
    @title = helpers.event_title_fields(event: @event, cols: @event.train? ? 3 : nil)
    if @event.match?
      @fields = helpers.match_show_fields(event: @event)
    elsif @event.train?
      @fields = helpers.training_show_fields(event: @event)
    end
  end

  # GET /events/new
  def new
		check_access(roles: [:admin, :coach])
    @event  = Event.prepare(event_params)
    if @event
      if @event.rest? or (@event.team_id >0 and @event.team.has_coach(current_user.person.coach_id))
        if params[:season_id]
          @season = Season.find(event_params[:season_id])
        else
          @season = (@event.team and @event.team_id > 0) ? @event.team.season : Season.last
        end
        @title  = helpers.event_title_fields(event: @event, form: true, cols: @event.match? ? 2 : nil)
        @fields = [[{kind: "gap"}, {kind: "label", value: I18n.t("match.rival")}, {kind: "text-box", key: :name, value: I18n.t("match.default_rival")} ]] if @event.match?
      else
        redirect_to(current_user.admin? ? "/slots" : @event.team)
      end
    else
      redirect_to(current_user.admin? ? "/slots" : "/", data: {turbo_action: "replace"})
    end
  end

  # GET /events/1/edit
  def edit
    check_access(roles: [:admin], obj: @event)
    if params[:season_id]
      @season = Season.find(params[:season_id])
    else
      @season = (@event.team and @event.team_id > 0) ? @event.team.season : Season.last
    end
    @drills = @event.drill_list if @event.train?
    @title  = helpers.event_title_fields(event: @event, form: true, cols: @event.match? ? 2 : nil)
    @fields = helpers.match_form_fields(event: @event) if @event.match?
  end

  # POST /events or /events.json
  def create
    @event = Event.prepare(event_params)
    check_access(roles: [:admin], obj: @event, returl: events_url)
    respond_to do |format|
      @event.rebuild(event_params)
      if @event.save
        link_holidays
        format.html { redirect_to @event.team_id > 0 ? team_path(@event.team) : events_url, notice: helpers.event_create_notice, data: {turbo_action: "replace"} }
        format.json { render :show, status: :created, location: events_path}
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    check_access(roles: [:admin], obj: @event, returl: events_url)
    respond_to do |format|
      e_data = event_params
      @event.rebuild(e_data)
      if e_data[:player_ids]  # we are updating attendance
        check_attendance(e_data[:player_ids])
        format.html { redirect_to @event, notice: helpers.event_update_notice, data: {turbo_action: "replace"}}
        format.json { render :show, status: :ok, location: @event }
      elsif e_data[:task]
        check_task(e_data[:task]) # updated task from edit_task_form (add or edit)
        format.html { redirect_to e_data[:task][:retlnk], notice: helpers.flash_message("#{I18n.t("task.updated")} '#{@task.to_s}'", "success") }
        format.json { render :edit, status: :ok, location: @event }
      elsif @event.save
        if e_data[:season_id].to_i > 0 # season event
          format.html { redirect_to season_path(e_data[:season_id]), notice: helpers.event_update_notice, data: {turbo_action: "replace"} }
          format.json { render :show, status: :ok, location: @event }
        elsif e_data[:tasks_attributes] # a training session
          @event.tasks.reload
          format.html { redirect_to @event, notice:helpers.event_update_notice }
          format.json { render :show, status: :ok, location: @event }
        else # updating match
          format.html { redirect_to @event, notice: helpers.event_update_notice, data: {turbo_action: "replace"} }
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    check_access(roles: [:admin], obj: @event, returl: events_url)
    erase_links
    e_name = @event.to_s
    team   = @event.team
    @event.destroy
    respond_to do |format|
      next_url = team.id > 0 ? team_path : events_url
      next_act = team.id > 0 ? :show : :index
      format.html { redirect_to next_url, action: next_act.to_sym, status: :see_other, notice: helpers.event_delete_notice, data: {turbo_action: "replace"} }
      format.json { head :no_content }
    end
  end

  # GET /events/1/show_task
  def show_task
    check_access(roles: [:admin, :coach], returl: events_url)
    @task   = Task.find(params[:task_id])
    @fields = helpers.task_show_fields(@task)
  end

  # GET /events/1/add_task
  def add_task
    check_access(roles: [:admin], obj: @event, returl: events_url)
    prepare_task_form(subtitle: I18n.t("task.add"), retlnk: edit_event_path(@event), search_in: add_task_event_path(@event))
  end

  # GET /events/1/edit_task
  def edit_task
    check_access(roles: [:admin], obj: @event, returl: events_url)
    prepare_task_form(subtitle: I18n.t("task.edit"), retlnk: event_path(@event), search_in: edit_task_event_path(@event), task_id: true)
  end

  # GET /events/1/load_chart
  def load_chart
    check_access(roles: [:admin, :coach])
    @header = helpers.event_title_fields(event: @event, cols: @event.train? ? 3 : nil)
    @chart  = helpers.event_workload(params[:name])
  end

  # GET /events/1/attendance
  def attendance
    check_access(roles: [:admin, :coach])
    @title  = helpers.event_attendance_title(event: @event)
    @fields = helpers.event_attendance_form_fields(event: @event)
  end

  private
 		# check attendance
		def check_attendance(p_array)
			# first pass
			attendees = Array.new	# array to include all player_ids
			p_array.each {|p| attendees <<  Player.find(p.to_i) unless (p=="" or p.to_i==0)}

			# second pass - manage associations
			attendees.each {|p| @event.players << p unless @event.has_player(p.id)}

			# cleanup removed attendances
			@event.players.each {|p| @event.players.delete(p) unless attendees.include?(p)}
		end

    # ensure a task is correctly added to event
    def check_task(t_dat)
      if t_dat  # we are adding a single task
        @task          = (t_dat[:task_id] and t_dat[:task_id]!="") ? Task.find(t_dat[:task_id]) : Task.new(event_id: @event.id)
        @task.order    = t_dat[:order].to_i if t_dat[:order]
        @task.drill_id = t_dat[:drill_id] ? t_dat[:drill_id].to_i : params[:task][:drill_id].split("|")[0].to_i
        @task.duration = t_dat[:duration].to_i if t_dat[:duration]
        @task.remarks  = t_dat[:remarks] if t_dat[:remarks]
        @task.save
      end
    end

    def link_holidays
      if @event
        if @event.rest? and @event.team_id==0  # general holiday
          season = Season.search_date(@event.start_date)
          if season # we have a season for this event
            season.teams.real.each { |team| # copy event to all teams
              e_copy = @event.dup
              e_copy.team_id = team.id
              e_copy.save
              team.events << e_copy
            }
          end
        end
      end
    end

    # Remove any links to this event prior to deleting it
    def erase_links
      if @event
        case @event.kind.to_sym
        when :rest
          purge_holiday if @event.team_id==0  # clean off copies
        when :train
          purge_train
        when :match
          purge_match
        end
      end
    end

    # Remove holidays linked to a general holiday
    def purge_holiday
      season = Season.search_date(@event.start_date)
      if season # we have a season for this event
        season.teams.real.each { |team| # delete event to all teams
          e_copy = Event.holidays.where(team_id: team.id, name: @event.name, start_time: @event.start_time).first
          e_copy.delete if e_copy # delete linked event
        }
      end
    end

    # purge associated tasks
    def purge_train
      @event.tasks.each { |t| t.delete }
      @event.event_targets.each { |t| t.delete }
      @event.players.each { |t| t.delete }
    end

    # purge assocaited tasks
    def purge_match
      @event.match.delete
      @event.players.each { |t| t.delete }
    end

    # prepare edit/add task form
    def prepare_task_form(subtitle:, retlnk:, search_in:, task_id: nil)
      get_task(load_drills: true) # get the right @task/@drill
      @title       = helpers.event_task_title(event: @event, subtitle: subtitle)
      @search      = helpers.drill_search_bar(search_in: search_in, task_id: task_id ? @task.id : nil)
      @fields      = helpers.task_form_fields(search_in: search_in, retlnk: retlnk)
      @description = helpers.task_form_description
      @remarks     = helpers.task_form_remarks
    end

    # determine task/drill objects from params received
    def get_task(load_drills: nil)
      if params[:event]
        t_param = event_params[:task]
      elsif params[:task] # comes from a dynamic refresh
        tmp     = params[:task][:drill_id].split("|")
        t_param = {drill_id: tmp[0], task_id: tmp[1]}
      else
        t_param = params
      end
      @task   = t_param[:task_id] ? Task.find(t_param[:task_id]) : Task.new(event: @event, order: @event.tasks.count + 1, duration: 5)
      if load_drills
        @drills = filter!(Drill).pluck(:name, :id)
        @drill  = t_param[:drill_id] ? Drill.find(t_param[:drill_id]) : (@task.drill ? @task.drill : @drills.size>0 ? Drill.find(@drills.first[1]) : nil)
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event  = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(
          :id,
          :name,
          :kind,
          :home,
          :start_date,
          :start_time,
          :end_time,
          :hour,
          :min,
          :duration,
          :team_id,
          :p_for,
          :p_opp,
          :task_id,
          :drill_id,
          :skill_id,
          :kind_id,
          :location_id,
          :season_id,
          player_ids: [],
          stats: [],
          event_targets_attributes: [:id, :priority, :event_id, :target_id, :_destroy, target_attributes: [:id, :focus, :aspect, :concept]],
          task: [:id, :task_id, :order, :drill_id, :duration, :remarks, :retlnk],
          tasks_attributes: [:id, :order, :drill_id, :duration, :remarks, :_destroy]
        )
    end
end
