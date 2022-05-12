class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit add_task show_task edit_task update destroy ]

  # GET /events or /events.json
  def index
    if current_user.present?
      @events = Event.search(params)
      @season = Season.last if @events.empty?
      @header_fields = general_header(I18n.t(:l_cal))
    else
      redirect_to "/"
    end
  end

  # GET /events/1 or /events/1.json
  def show
    unless current_user.present? and (current_user.admin? or current_user.is_coach?)
      redirect_to "/"
    end
    @header_fields = event_header(@event.title(show: true))
  end

  # GET /events/1 or /events/1.json
  def details
    unless current_user.present? and (current_user.admin? or current_user.is_coach?)
      redirect_to "/"
    end
    @header_fields = event_header(@event.team.to_s)
  end

  # GET /events/new
  def new
    if current_user.present? and (current_user.admin? or current_user.is_coach?)
      @event  = Event.prepare(event_params)
      if @event
        if @event.rest? or (@event.team_id >0 and @event.team.has_coach(current_user.person.coach_id))
          if params[:season_id]
            @season = Season.find(event_params[:season_id])
          else
            @season = (@event.team and @event.team_id > 0) ? @event.team.season : Season.last
          end
          @header_fields = event_header(@event.title)
        else
          redirect_to(current_user.admin? ? "/slots" : @event.team)
        end
      else
        redirect_to(current_user.admin? ? "/slots" : "/")
      end
    else
      redirect_to "/"
    end
  end

  # GET /events/1/edit
  def edit
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      if params[:season_id]
        @season = Season.find(params[:season_id])
      else
        @season = (@event.team and @event.team_id > 0) ? @event.team.season : Season.last
      end
      @drills        = @event.drill_list
      @header_fields = event_header(@event.title)
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # POST /events or /events.json
  def create
    @event = Event.prepare(event_params)
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      respond_to do |format|
        rebuild_event(event_params)
        if @event.save
          link_holidays
          format.html { redirect_to @event.team_id > 0 ? team_path(@event.team) : events_url, notice: event_create_notice }
          format.json { render :show, status: :created, location: events_path}
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      respond_to do |format|
        rebuild_event(event_params)
        if @event.save
          if @task  # we just updated a task
            format.html { redirect_to edit_event_path(@event), notice: t(:task_created) + "'#{@task.to_s}'" }
            format.json { render :edit, status: :ok, location: @event }
          elsif params[:event][:season_id].to_i > 0 # season event
            format.html { redirect_to season_path(params[:event][:season_id]), notice: event_update_notice }
            format.json { render :show, status: :ok, location: @event }
          elsif params[:event][:p_for]==nil
            @event.tasks.reload
            format.html { redirect_to @event, notice: event_update_notice }
            format.json { render :show, status: :ok, location: @event }
          else # updating match
            format.html { redirect_to team_path(@event.team_id), notice: t(:match_updated) + "'#{@event.to_s}'" }
          end
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      erase_links
      e_name = @event.to_s
      team = @event.team
      @event.destroy
      respond_to do |format|
        format.html { redirect_to team.id > 0 ? team_path(team) : events_url, notice: event_delete_notice }
        format.json { head :no_content }
      end
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/show_task
  def show_task
    if current_user.present? and (current_user.admin? or current_user.is_coach?)
      @task = Task.find(params[:task_id])
      @header_fields = event_header(@event.title(show: true))
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/add_task
  def add_task
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      @task          = Task.new(event: @event, order: @event.tasks.count + 1)
      @drills        = Drill.search(params[:search])
      @header_fields = task_header(I18n.t(:l_task_add), add_task_event_path(@event))
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/edit_task
  def edit_task
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      @task = Task.find(params[:task_id])
      @drills = Drill.search(params[:search])
      @header_fields = task_header(I18n.t(:l_task_edit), edit_task_event_path(@event))
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  private

    # return icon and top of HeaderComponent
    def general_header(title)
      return [
        [{kind: "header-icon", value: "calendar.svg"}, {kind: "title", value: title, cols: cols}],
        [{kind: "subtitle", value: @team ? @team.name : @season ? @season.name : ""}]
      ]
    end

    # return icon and top of HeaderComponent
    def event_header(title, cols: nil)
      res   = [[{kind: "header-icon", value: @event.pic, rows: 2}, {kind: "title", value: title}, {kind: "gap"}, {kind: "icon-label", icon: "calendar.svg", value: @event.date_string}]]
      case @event.kind.to_sym
      when :rest
        res << [{kind: "subtitle", value: @team ? @team.name : @season ? @season.name : "", cols: 3}]
        res << [{kind: "label", value: @event.name, cols: 3, align: "center"}]
      when :match
        if @event.location.gmaps_url
          res << [{kind: "location", icon: "gmaps.svg", url: @event.location.gmaps_url, label: @event.location.name}, {kind: "gap"}]
        else
          res << [{kind: "gap", cols: 2}]
        end
        res.last << {kind: "icon-label", icon: "clock.svg", value: @event.time_string}
      when :train
        res << [{kind: "subtitle", value: I18n.t(:l_train)}, {kind: "gap"}, {kind: "icon-label", icon: "clock.svg", value: @event.time_string}]
      end
      res
    end

    # return HeaderComponent @fields for forms
    def event_form_fields(title, cols: nil)
      res = header_fields(title, cols: cols)
      res << [{kind: "label", align: "right", value: I18n.t(:l_name)}, {kind: "text-box", key: :name, value: @team.name}]
      res << [{kind: "icon", value: "category.svg"}, {kind: "select-collection", key: :category_id, collection: Category.real, value: @team.category_id}]
      res << [{kind: "icon", value: "division.svg"}, {kind: "select-collection", key: :division_id, collection: Division.real, value: @team.division_id}]
      res << [{kind: "icon", value: "location.svg"}, {kind: "select-collection", key: :homecourt_id, collection: Location.home, value: @team.homecourt_id}]
      res
    end

    # return icon and top of HeaderComponent
    def task_header(title, search_in, cols: nil)
      res   = [[{kind: "header-icon", value: "drill.svg", rows: 2}, {kind: "title", value: title}]]
      res << [{kind: "search-text", url: search_in}]
      res
    end

    def rebuild_event(event_params)
      @event = Event.new unless @event
      @event.start_time = event_params[:start_time] if event_params[:start_time]
      @event.hour       = event_params[:hour].to_i if event_params[:hour]
      @event.min        = event_params[:min].to_i if event_params[:min]
      @event.duration   = event_params[:duration].to_i if event_params[:duration]
      @event.name       = event_params[:name] if event_params[:name]
      @event.p_for      = event_params[:p_for].to_i if event_params[:p_for]
      @event.p_opp      = event_params[:p_opp].to_i if event_params[:p_opp]
      @event.location_id= event_params[:location_id].to_i if event_params[:location_id]
      @event.home       = event_params[:home] if event_params[:home]
      check_targets(event_params[:event_targets_attributes]) if event_params[:event_targets_attributes]
      check_tasks(event_params[:tasks_attributes]) if event_params[:tasks_attributes]
      check_new_task(event_params[:task]) if event_params[:task]
    end

    # checks targets_attributes parameter received and manage adding/removing
    # from the target collection - remove duplicates from list
    def check_targets(t_array)
      a_targets = Array.new	# array to include only non-duplicates
      t_array.each { |t| # first pass
        if t[1][:_destroy]  # we ust include to remove it
          a_targets << t[1]
        else
          a_targets << t[1] unless a_targets.detect { |a| a[:target_attributes][:concept] == t[1][:target_attributes][:concept] }
        end
      }
      a_targets.each { |t| # second pass - manage associations
        if t[:_destroy] == "1"	# remove drill_target
          @event.targets.delete(t[:target_attributes][:id].to_i)
        elsif t[:target_attributes]
          dt = EventTarget.fetch(t)
          @event.event_targets ? @event.event_targets << dt : @event.event_targets |= dt
        end
      }
    end

    # checks tasks_attributes parameter received and manage adding/removing
    # from the task collection - ALLOWING DUPLICATES.
    def check_tasks(t_array)
      t_array.each { |t| # manage associations
        if t[1][:_destroy] == "1"	# delete task
          Task.find(t[1][:id].to_i).delete
        else
          tsk = Task.fetch(t[1])
          tsk.save
        end
      }
    end

    # ensure a new task is correctly added to event
    def check_new_task(t_dat)
      if t_dat  # we are adding a single task
        @task          = Task.new(event_id: @event.id) unless @task
        @task.order    = t_dat[:order].to_i if t_dat[:order]
        @task.drill_id = t_dat[:drill_id].to_i if t_dat[:drill_id]
        @task.duration = t_dat[:duration].to_i if t_dat[:duration]
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
    end

    # purge assocaited tasks
    def purge_match
      @event.match.delete
    end

    # return adequate notice depending on @event kind
    def event_create_notice
      case @event.kind.to_sym
      when :rest
        t(:holiday_created) + "#{@event.to_s}"
      when :train
        t(:train_created) + "#{@event.date_string}"
      when :match
        t(:match_created) + "#{@event.to_s}"
      end
    end

    # return adequate notice depending on @event kind
    def event_update_notice
      case @event.kind.to_sym
      when :rest
        t(:holiday_updated) + "#{@event.to_s}"
      when :train
        t(:train_updated) + "#{@event.date_string}"
      when :match
        t(:match_updated) + "#{@event.to_s(true)}"
      end
    end

    # return adequate notice depending on @event kind
    def event_delete_notice
      case @event.kind.to_sym
      when :rest
        t(:holiday_deleted) + "#{@event.to_s}"
      when :train
        t(:train_deleted) + "#{@event.date_string}"
      when :match
        t(:match_deleted) + "#{@event.to_s(true)}"
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:id, :name, :kind, :home, :start_time, :end_time, :hour, :min, :duration, :team_id, :p_for, :p_opp, :drill_id, :location_id, :season_id, event_targets_attributes: [:id, :priority, :event_id, :target_id, :_destroy, target_attributes: [:id, :focus, :aspect, :concept]], task: [:id, :order, :drill_id, :duration], tasks_attributes: [:id, :order, :drill_id, :duration, :_destroy] )
    end
end
