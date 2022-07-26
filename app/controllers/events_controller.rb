class EventsController < ApplicationController
  include Filterable
  before_action :set_event, only: %i[ show edit add_task show_task edit_task load_chart attendance update destroy ]

  # GET /events or /events.json
  def index
    if current_user.present?
      @events = Event.search(params)
      @team   = Team.find(params[:team_id]) if params[:team_id]
      @season = @events.empty? ? Season.last : @events.first.team.season
      @title  = general_title
      @grid   = event_grid(events: @events, obj: @team ? @team : @season, retlnk: @team ? team_path(@team) : season_path(@season))
    else
      redirect_to "/", data: {turbo_action: "replace"}
    end
  end

  # GET /events/1 or /events/1.json
  def show
    unless current_user.present? and (current_user.admin? or current_user.is_coach?)
      redirect_to "/", data: {turbo_action: "replace"}
    end
    @title  = event_title(@event.title(show: true), cols: @event.train? ? 3 : nil)
    if @event.match?
      @fields = [[
        {kind: "gap"},
        {kind: "top-cell", value: @event.score[:home][:team], cols: 2},
        {kind: "label", value: @event.score[:home][:points], class: "border px py"}#,
#        {kind: "link", icon: "attendance.svg", label: I18n.t("calendar.attendance"), url: attendance_event_path, frame: "modal", align: "right"}
      ]]
      @fields << [
        {kind: "gap"},
        {kind: "top-cell", value: @event.score[:away][:team], cols: 2},
        {kind: "label", value: @event.score[:away][:points], class: "border px py"}
      ]
    elsif @event.train?
      @title << [workload_button(@event, align: "right"), {kind: "gap"}, {kind: "gap", cols: 2}, {kind: "link", icon: "attendance.svg", label: I18n.t("calendar.attendance"), url: attendance_event_path, frame: "modal", align: "right"}]
      @title << [{kind: "side-cell", value: I18n.t("target.abbr"),rows: 2}, {kind: "top-cell", value: I18n.t("target.focus.def_a")}, {kind: "lines", value: @event.def_targets, cols: 5}]
      @title << [{kind: "top-cell", value: I18n.t("target.focus.ofe_a")}, {kind: "lines", class: "align-top border px py", value: @event.off_targets, cols: 5}]
      #@title << [{kind: "top-cell", value: "A"}, {kind: "top-cell", value: "B"}, {kind: "top-cell", value: "C"}, {kind: "top-cell", value: "D"}, {kind: "top-cell", value: "E"}, {kind: "top-cell", value: "F"}]
      @fields = show_training_fields
    end
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
          @title = event_title(@event.title, form: true, cols: @event.match? ? 2 : nil)
        else
          redirect_to(current_user.admin? ? "/slots" : @event.team)
        end
      else
        redirect_to(current_user.admin? ? "/slots" : "/", data: {turbo_action: "replace"})
      end
    else
      redirect_to "/", data: {turbo_action: "replace"}
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
      @drills = @event.drill_list if @event.train?
      @title  = event_title(@event.title(show: true), form: true, cols: @event.match? ? 2 : nil)
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
          format.html { redirect_to @event.team_id > 0 ? team_path(@event.team) : events_url, notice: {kind: "success", message: event_create_notice}, data: {turbo_action: "replace"} }
          format.json { render :show, status: :created, location: events_path}
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to(current_user.present? ? events_url : "/", data: {turbo_action: "replace"})
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      respond_to do |format|
        if event_params[:player_ids]  # we are updating attendance
          check_attendance(event_params[:player_ids])
          format.html { redirect_to @event, notice: {kind: "success", message: event_update_notice}, data: {turbo_action: "replace"}}
          format.json { render :show, status: :ok, location: @event }
        else
          rebuild_event(event_params)
          if @event.save
            if @task  # we just updated a task
              format.html { redirect_to event_params[:task][:retlnk], notice: {kind: "success", message: "#{I18n.t("task.updated")} '#{@task.to_s}'"} }
              format.json { render :edit, status: :ok, location: @event }
            elsif event_params[:season_id].to_i > 0 # season event
              format.html { redirect_to season_path(params[:event][:season_id]), notice: {kind: "success", message: event_update_notice}, data: {turbo_action: "replace"} }
              format.json { render :show, status: :ok, location: @event }
            elsif event_params[:tasks_attributes] # a training session
              @event.tasks.reload
              format.html { redirect_to @event, notice: {kind: "success", message: event_update_notice}}
              format.json { render :show, status: :ok, location: @event }
            else # updating match
              format.html { redirect_to team_path(@event.team_id), notice: {kind: "success", message: "#{I18n.t("match.updated")} '#{@event.to_s}'"}, data: {turbo_action: "replace"} }
            end
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @event.errors, status: :unprocessable_entity }
          end
        end
      end
    else
      redirect_to(current_user.present? ? events_url : "/", data: {turbo_action: "replace"})
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      erase_links
      e_name = @event.to_s
      team   = @event.team
      @event.destroy
      respond_to do |format|
        next_url = team.id > 0 ? team_path : events_url
        next_act = team.id > 0 ? :show : :index
        format.html { redirect_to next_url, action: next_act.to_sym, status: :see_other, notice: {kind: "success", message: event_delete_notice}, data: {turbo_action: "replace"} }
        format.json { head :no_content }
      end
    else
      redirect_to(current_user.present? ? events_url : "/", data: {turbo_action: "replace"})
    end
  end

  # GET /events/1/show_task
  def show_task
    if current_user.present? and (current_user.admin? or current_user.is_coach?)
      @task   = Task.find(params[:task_id])
      @fields = task_fields(@task)
    else
      redirect_to(current_user.present? ? events_url : "/", data: {turbo_action: "replace"})
    end
  end

  # GET /events/1/add_task
  def add_task
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      @task   = Task.new(event: @event, order: @event.tasks.count + 1, duration: 5)
      #@drills = Drill.search(params[:search])
      @drills = filter!(Drill)
      @title  = task_title(I18n.t("task.add"))
      @retlnk = edit_event_path(@event)
      @search = drill_search_bar(add_task_event_path(@event))
      @fields = task_form_fields
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/edit_task
  def edit_task
    if current_user.present? and (current_user.admin? or @event.team.has_coach(current_user.person.coach_id))
      @task   = Task.find(params[:task_id])
      @drills = filter!(Drill)
      @title  = task_title(I18n.t("task.edit"))
      @retlnk = event_path(@event)
      @search = drill_search_bar(edit_task_event_path(@event), task_id: @task.id)
      @fields = task_form_fields
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/load_chart
  def load_chart
    @header = event_title(@event.title(show: true), cols: @event.train? ? 3 : nil)
    @chart  = workload_profile(params[:name])
  end

  # GET /events/1/attendance
  def attendance
    @title   = event_title(@event.title(show: true), cols: @event.match? ? 2 : nil)
    @title << [{kind: "gap"}, {kind: "side-cell", value: I18n.t("calendar.attendance")}]
    @players = @event.team.players
  end

  private

    # return icon and top of FieldsComponent
    def general_title
      title    = @team ? (@team.name + " (#{@team.season.name})") : @season ? @season.name : I18n.t("calendar.label")
      subtitle = (title == I18n.t("calendar.label")) ? I18n.t("scope.all") : I18n.t("calendar.label")
      res      = title_start(icon: "calendar.svg", title: title)
      res << [{kind: "subtitle", value: subtitle}]
      res
    end

    # return icon and top of FieldsComponent
    def event_title(title, subtitle: nil, form: nil, cols: nil)
      rows = @event.rest? ? 3 : nil
      res  = title_start(icon: @event.pic, title: title, rows: rows, cols: cols)
      res.last << {kind: "gap"}
      case @event.kind.to_sym
      when :rest
        res << [{kind: "subtitle", value: @team ? @team.name : @season ? @season.name : "", cols: cols}] if @team or @season
        res << [form ? {kind: "text-box", key: :name, value: @event.name} : {kind: "label", value: @event.name}]
      when :match
        if form
          res << [{kind: "icon", value: "location.svg"}, {kind: "select-collection", key: :location_id, options: Location.home, value: @event.location_id}, {kind: "gap"}]
        else
          if @event.location.gmaps_url
            res << [{kind: "location", icon: "gmaps.svg", url: @event.location.gmaps_url, label: @event.location.name}, {kind: "gap"}]
          else
            res << [{kind: "gap", cols: 2}]
          end
        end
      when :train
        res << [{kind: "subtitle", value: subtitle ? subtitle : I18n.t("train.single"), cols: cols}, {kind: "gap"}]
      end
      if form # top right corner of title
        res.first << {kind: "icon", value: "calendar.svg"}
        res.first << {kind: "date-box", key: :start_date, s_year: @event.team_id > 0 ? @event.team.season.start_date : @event.start_date, e_year: @event.team_id > 0 ? @event.team.season.end_year : nil, value: @event.start_date}
        unless @event.rest? # add start_time inputs
          res.last << {kind: "icon", value: "clock.svg"}
          res.last << {kind: "time-box", key: :hour, hour: @event.hour, min: @event.min}
          res = res + match_fields if @event.match?
        end
        res.last << {kind: "hidden", key: :season_id, value: @season.id} if @event.team.id==0
        res.last << {kind: "hidden", key: :team_id, value: @event.team_id}
        res.last << {kind: "hidden", key: :kind, value: @event.kind}
      else
        res.first << {kind: "icon-label", icon: "calendar.svg", value: @event.date_string}
        res.last << {kind: "icon-label", icon: "clock.svg", value: @event.time_string} unless @event.rest?
      end
      res
    end

    # return FieldsComponent @fields for show_training
    def show_training_fields
      res = [[{kind: "gap", size: 2}, {kind: "accordion", title: I18n.t("task.many"), tail: "#{I18n.t("stat.total")}:" + " " + @event.work_duration, objects: task_accordion(@event), cols: 4}]]
    end

    # return icon and top of FieldsComponent for Tasks
    def task_title(title)
      res = event_title(@event.title(show: true), subtitle: title, cols: 3)
    end

    # fields to show in task views
    def task_fields(task, title: true)
      res = []
      res << [{kind: "icon", value: "drill.svg", size: "30x30", align: "center"}, {kind: "label", value: task.drill.name}, {kind: "gap"}, {kind: "icon-label", icon: "clock.svg", value: task.s_dur}] if title
      res << [{kind: "cell", value: task.drill.explanation.empty? ? task.drill.description : task.drill.explanation}]
      if task.remarks?
        res << [{kind: "label", value: I18n.t("task.remarks")}]
        res << [{kind: "cell", value: task.remarks, size: 28}]
      end
      res << [{kind: "gap", cols: 2}, {kind: "edit", align: "right", url: edit_task_event_path(task_id: task.id)}] if @event.team.has_coach(current_user.person.coach_id)
      res
    end

    # fields for task edit/add views
    def task_form_fields
      @remarks=[
        [{kind: "label", value: I18n.t("task.remarks")}],
        [{kind: "rich-text-area", key: :remarks, value: @task.remarks, size: 28}],
      ]
      res = [
        [
          {kind: "top-cell", value: I18n.t("task.number")},
          {kind: "top-cell", value: I18n.t("drill.single")},
          {kind: "top-cell", value: I18n.t("task.duration")}
        ],
        [
          {kind: "side-cell", value: @task.order},
          {kind: "select-collection", key: :drill_id, options: @drills, value: @task.drill_id},
          {kind: "number-box", key: :duration, min: 1, max: 90, size: 3, value: @task.duration}
        ],
        [
          {kind: "hidden", key: :id, value: @task.id},
          {kind: "hidden", key: :order, value: @task.order},
          {kind: "hidden", key: :retlnk, value: @retlnk}
        ]
      ]
    end

    # return FieldsComponent for match form
    def match_fields
      score = @event.score(0)
      res = [[{kind: "gap", cols: 6}]]
      res << [{kind: "side-cell", value: I18n.t("team.home_a"), rows: 2}, {kind: "radio-button", key: :home, value: true, checked: @event.home, align: "right", class: "align-center"}, {kind: "top-cell", value: @event.team.to_s, cols: 2}, {kind: "number-box", key: :p_for, min: 0, max: 200, size: 3, value: score[:home][:points]}]
      res << [{kind: "radio-button", key: :home, value: false, checked: @event.home==false, align: "right", class: "align-center",}, {kind: "text-box", key: :name, value: @event.name, cols: 2}, {kind: "number-box", key: :p_opp, min: 0, max: 200, size: 3, value: score[:away][:points]}]
      res
    end

    # return accordion for event tasks
    def task_accordion(event)
      tasks   = Array.new
      event.tasks.order(:order).each { |task|
        item = {}
        item[:url]     = show_task_event_path(task_id: task.id)
        item[:turbo]   = "modal"
        item[:head]    = task.headstring
        item[:content] = FieldsComponent.new(fields: task_fields(task, title: nil))
        tasks << item
      }
      tasks
    end

    # return the dropdowFistron element to access workload charts
    def workload_button(event, cols: 2, align: "center")
      res = { kind: "dropdown", align:, cols:,
        button: {kind: "link", icon: "pie.svg", size: "20x20", label: I18n.t("train.workload"), name: "show-chart",
          options: [
            {label: I18n.t("kind.single"), url: load_chart_event_path(name: "kind"), data: {turbo_frame: :modal}},
            #{label: I18n.t("target.many"), url: load_chart_event_path(name: "target"), data: {turbo_frame: :modal}},
            {label: I18n.t("skill.single"), url: load_chart_event_path(name: "skill"), data: {turbo_frame: :modal}}
          ]
        }
      }
    end

    # profile of event workload (task types)
    # returns a hash with time used split by kinds & skills
    def workload_profile(name)
      title = I18n.t("train.workload_by") + " " + I18n.t("#{name}.single")
      data  = {}
      @event.tasks.each { |task| # kind
        case name
        when "kind"
          k_name = task.drill.kind.name
          data[k_name] = data[k_name] ? data[k_name] + task.duration : task.duration
        when "skill"
          task.drill.skills.each {|skill|
            s_name = skill.concept
            data[s_name] = data[s_name] ? data[s_name] + task.duration : task.duration
          }
#        when "target"
#           binding.break
#           task.drill.targets.each {|target|
#            t_name = target.concept
#            data[t_name] = data[t_name] ? data[t_name] + task.duration : task.duration if target.priority==1
#          }
        end
      }
      {title: title, data: data}
    end

    def rebuild_event(event_params)
      @event = Event.new unless @event
      @event.start_time = event_params[:start_date] if event_params[:start_date]
      @event.hour       = event_params[:hour].to_i if event_params[:hour]
      @event.min        = event_params[:min].to_i if event_params[:min]
      @event.duration   = event_params[:duration].to_i if event_params[:duration]
      @event.name       = event_params[:name] if event_params[:name]
      @event.p_for      = event_params[:p_for].to_i if event_params[:p_for]
      @event.p_opp      = event_params[:p_opp].to_i if event_params[:p_opp]
      @event.location_id= event_params[:location_id].to_i if event_params[:location_id]
      @event.home       = event_params[:home] if event_params[:home]
      check_targets(event_params[:event_targets_attributes]) if event_params[:event_targets_attributes]
      if event_params[:tasks_attributes]  # updated tasks in session edit form
        check_tasks(event_params[:tasks_attributes])
      elsif event_params[:task] # updated task from edit_task_form (add or edit)
        check_task(event_params[:task])
      end
    end

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

    # ensure a task is correctly added to event
    def check_task(t_dat)
      if t_dat  # we are adding a single task
        @task          = (t_dat[:id] and t_dat[:id]!="") ? Task.find(t_dat[:id]) : Task.new(event_id: @event.id)
        @task.order    = t_dat[:order].to_i if t_dat[:order]
        @task.drill_id = params[:task][:drill_id].to_i if params[:task][:drill_id] #t_dat[:drill_id].to_i if t_dat[:drill_id]
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

    # return adequate notice depending on @event kind
    def event_create_notice
      case @event.kind.to_sym
      when :rest
        t("holiday.created") + "#{@event.to_s}"
      when :train
        t("train.created") + "#{@event.date_string}"
      when :match
        t("match.created") + "#{@event.to_s}"
      end
    end

    # return adequate notice depending on @event kind
    def event_update_notice
      case @event.kind.to_sym
      when :rest
        t("holiday.updated") + "#{@event.to_s}"
      when :train
        t("train.updated") + "#{@event.date_string}"
      when :match
        t("match.updated") + "#{@event.to_s(true)}"
      end
    end

    # return adequate notice depending on @event kind
    def event_delete_notice
      case @event.kind.to_sym
      when :rest
        t("holiday.deleted") + "#{@event.to_s}"
      when :train
        t("train.deleted") + "#{@event.date_string}"
      when :match
        t("match.deleted") + "#{@event.to_s(true)}"
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:id, :name, :kind, :home, :start_date, :start_time, :end_time, :hour, :min, :duration, :team_id, :p_for, :p_opp, :task_id, :drill_id, :skill_id, :kind_id, :location_id, :season_id, player_ids: [], event_targets_attributes: [:id, :priority, :event_id, :target_id, :_destroy, target_attributes: [:id, :focus, :aspect, :concept]], task: [:id, :order, :drill_id, :duration, :remarks, :retlnk], tasks_attributes: [:id, :order, :drill_id, :duration, :remarks, :_destroy] )
    end
end
