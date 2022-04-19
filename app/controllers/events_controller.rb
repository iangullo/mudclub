class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit add_task show_task edit_task update destroy ]

  # GET /events or /events.json
  def index
    if current_user.present?
      @events = Event.search(params)
      @season = Season.last if @events.empty?
    else
      redirect_to "/"
    end
  end

  # GET /events/1 or /events/1.json
  def show
    unless current_user.present?
      redirect_to "/"
    end
  end

  # GET /events/1 or /events/1.json
  def details
    unless current_user.present?
      redirect_to "/"
    end
  end
  # GET /events/new
  def new
    if current_user.present? and (current_user.admin? or current_user.is_coach?)
      @event  = Event.prepare(event_params)
      if @event and (@event.holiday? or (@event.team_id >0 and @event.team.has_coach(current_user.person.coach_id)))
        @season = (@event.team and @event.team_id > 0) ? @event.team.season : Season.last
      else
        redirect_to(current_user.admin? ? "/slots" : @event.team)
      end
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/edit
  def edit
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      @season = (@event.team and @event.team_id > 0) ? @event.team.season : Season.last
      @drills = @event.drill_list
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
          format.html { redirect_to @event.team_id > 0 ? team_path(@event.team) : events_url }
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
            format.html { redirect_to @event }
            format.json { render :show, status: :ok, location: @event }
          else
            format.html { redirect_to @event.team_id > 0 ? team_path(@event.team) : events_url }
            format.json { render :show, status: :ok, location: @event }
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
      team = @event.team
      @event.destroy
      respond_to do |format|
        format.html { redirect_to team.id > 0 ? team_path(team) : events_url }
        format.json { head :no_content }
      end
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/show_task
  def show_task
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      @task = Task.find(params[:task_id])
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/add_task
  def add_task
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      @task = Task.new(event: @event, order: @event.tasks.count + 1)
      @drills = Drill.search(params[:search])
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/edit_task
  def edit_task
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      @task = Task.find(params[:task_id])
      @drills = Drill.search(params[:search])
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  private
    def rebuild_event(event_params)
      @event = Event.new unless @event
      @event.start_time = event_params[:start_time] if event_params[:start_time]
      @event.hour       = event_params[:hour] if event_params[:hour]
      @event.min        = event_params[:min] if event_params[:min]
      @event.duration   = event_params[:duration].to_i if event_params[:duration]
      @event.name       = event_params[:name] if event_params[:name]
      check_targets(event_params[:event_targets_attributes]) if event_params[:event_targets_attributes]
      check_tasks(event_params) if event_params[:task] or event_params[:tasks_attributes]
    end

    # checks targets_attributes parameter received and manage adding/removing
    # from the target collection - remove duplicates from list
    def check_targets(t_array)
      a_targets = Array.new	# array to include only non-duplicates
      t_array.each { |t| # first pass
        a_targets << t[1] unless a_targets.detect { |a| a[:target_attributes][:concept] == t[1][:target_attributes][:concept] }
      }
      a_targets.each { |t| # second pass - manage associations
        if t[:_destroy] == "1"	# remove drill_target
          @event.targets.delete(t[:target_attributes][:id].to_i)
        else
          dt = EventTarget.fetch(t)
          @event.event_targets ? @event.event_targets << dt : @event.event_targets |= dt
        end
      }
    end

    # ensure task is correctly added to event
    def check_tasks(p_array)
      t = p_array[:task]
      a = p_array[:tasks_attributes]
      @task = Task.new(event_id: @event.id) unless @task
      if t  # we are adding a single task
        @task.order    = t[:order].to_i if t[:order]
        @task.drill_id = t[:drill_id].to_i if t[:drill_id]
        @task.duration = t[:duration].to_i if t[:duration]
        @task.save
      end
      if a  # we have edited the existing tasks
        a.each { |t_dat|
          tsk = Task.fetch(t_dat[1])
          tsk.event_id = @event.id
          tsk.save
        }
      end
    end

    def link_holidays
      if @event
        if @event.holiday? and @event.team_id==0  # general holiday
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
        when :holiday
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

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:id, :name, :kind, :start_time, :end_time, :hour, :min, :duration, :team_id, :drill_id, :location_id, :season_id, target_attributes: [:id, :focus, :aspect, :concept], event_targets_attributes: [:id, :priority, :_destroy], task: [:id, :order, :drill_id, :duration], tasks_attributes: [:id, :order, :drill_id, :duration] )
      params.fetch(:event, {})
    end
end
