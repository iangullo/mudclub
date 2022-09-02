class EventsController < ApplicationController
  include Filterable
  before_action :set_event, only: %i[ show edit add_task show_task edit_task task_drill load_chart attendance update destroy ]

  # GET /events or /events.json
  def index
    check_access(roles: [:user])
    @events = Event.search(params)
    @team   = Team.find(params[:team_id]) if params[:team_id]
    @season = @events.empty? ? Season.last : @events.first.team.season
    @title  = general_title
    if @team
      @grid = event_grid(events: @events, obj: @team, retlnk: team_events_path(@team))
    elsif @season
      @grid = event_grid(events: @events, obj: @season, retlnk: season_events_path(@season))
    else
      @grid = nil
    end
  end

  # GET /events/1 or /events/1.json
  def show
		check_access(roles: [:admin, :coach])
    @title = event_title(@event.title(show: true), cols: @event.train? ? 3 : nil)
    if @event.match?
      @fields = show_match_fields
    elsif @event.train?
      @fields = show_training_fields
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
        @title  = event_title(@event.title, form: true, cols: @event.match? ? 2 : nil)
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
    @title  = event_title(@event.title(show: true), form: true, cols: @event.match? ? 2 : nil)
    @fields = match_form_fields if @event.match?
  end

  # POST /events or /events.json
  def create
    @event = Event.prepare(event_params)
    check_access(roles: [:admin], obj: @event, returl: events_url)
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
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    check_access(roles: [:admin], obj: @event, returl: events_url)
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
            format.html { redirect_to @event, notice: {kind: "success", message: "#{I18n.t("match.updated")} '#{@event.to_s}'"}, data: {turbo_action: "replace"} }
          end
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
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
      format.html { redirect_to next_url, action: next_act.to_sym, status: :see_other, notice: {kind: "success", message: event_delete_notice}, data: {turbo_action: "replace"} }
      format.json { head :no_content }
    end
  end

  # GET /events/1/show_task
  def show_task
    check_access(roles: [:admin, :coach], returl: events_url)
    @task   = Task.find(params[:task_id])
    @fields = task_fields(@task)
  end

  # GET /events/1/add_task
  def add_task
    check_access(roles: [:admin], obj: @event, returl: events_url)
    get_task(load_drills: true) # get the right @task/@drill
    @title  = task_title(I18n.t("task.add"))
    @retlnk = edit_event_path(@event)
    @search = drill_search_bar(add_task_event_path(@event))
    @fields = task_form_fields(add_task_event_path(@event))
  end

  # GET /events/1/edit_task
  def edit_task
    check_access(roles: [:admin], obj: @event, returl: events_url)
    get_task(load_drills: true) # get the right @task/@drill
    @title  = task_title(I18n.t("task.edit"))
    @retlnk = event_path(@event)
    @search = drill_search_bar(edit_task_event_path(@event), task_id: @task.id)
    @fields = task_form_fields(edit_task_event_path(@event))
  end

  # GET /events/1/load_chart
  def load_chart
    check_access(roles: [:admin, :coach])
    @header = event_title(@event.title(show: true), cols: @event.train? ? 3 : nil)
    @chart  = workload_profile(params[:name])
  end

  # GET /events/1/attendance
  def attendance
    check_access(roles: [:admin, :coach])
    @title = title_start(icon: "attendance.svg", title: @event.team.name)
    @title[0] << {kind: "gap"}
    @title << [{kind: "subtitle", value: @event.to_s}, {kind: "gap"}]
    top_right_title(@title, nil)
    @title << [{kind: "gap", size:1, cols: 6, class: "text-xs"}]
    @fields = [[{kind: "gap", size: 2}, {kind: "side-cell", value: I18n.t(@event.match? ? "match.roster" : "calendar.attendance"), align: "left"}]]
    @fields << [{kind: "gap", size: 2}, {kind: "select-checkboxes", key: :player_ids, options: @event.team.players}]
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
      res = title_start(icon: @event.pic, title: title, rows: @event.rest? ? 3 : nil, cols: cols)
      res.last << {kind: "gap"}
      case @event.kind.to_sym
      when :rest then rest_title(res, cols)
      when :match then match_title(res, cols, form)
      when :train then train_title(res, cols, form, subtitle)
      end
      top_right_title(res, form)
      #res << [{kind: "top-cell", value: "A"}, {kind: "top-cell", value: "B"}, {kind: "top-cell", value: "C"}, {kind: "top-cell", value: "D"}, {kind: "top-cell", value: "E"}, {kind: "top-cell", value: "F"}]
      res << [{kind: "gap", size:1, cols: 6, class: "text-xs"}] unless @event.match? and form==nil
      res
    end

    # complete event title for matches
    def match_title(res, cols, form)
      if form
        res << [{kind: "icon", value: "location.svg"}, {kind: "select-collection", key: :location_id, options: Location.home, value: @event.location_id}, {kind: "gap"}]
        res << [{kind: "gap", size: 1, cols: 4}, {kind: "icon", value: "attendance.svg"}, {kind: "link", label: I18n.t("match.roster"), url: attendance_event_path, frame: "modal", align: "left"}] if @event.id
        #res << [{kind: "gap", size: 1, cols: 4}, {kind: "link", icon: "attendance.svg", label: I18n.t("match.roster"), url: attendance_event_path, frame: "modal", align: "left", cols: 2}]
      else
        if @event.location.gmaps_url
          res << [{kind: "location", icon: "gmaps.svg", url: @event.location.gmaps_url, label: @event.location.name}, {kind: "gap"}]
        else
          res << [{kind: "gap", cols: 2}]
        end
        res << [{kind: "gap", size: 1, cols: 3}, {kind: "link", icon: "attendance.svg", label: I18n.t("match.roster"), url: attendance_event_path, frame: "modal", align: "left", cols: 2}]
      end
    end

    # complete event_title for rest events
    def rest_title(res, cols)
      res << [{kind: "subtitle", value: @team ? @team.name : @season ? @season.name : "", cols: cols}] if @team or @season
      res << [form ? {kind: "text-box", key: :name, value: @event.name} : {kind: "label", value: @event.name}]
    end

    # complete event_title for train events
    def train_title(res, cols, form, subtitle)
      res << [{kind: "subtitle", value: subtitle ? subtitle : I18n.t("train.single"), cols: cols}, {kind: "gap"}]
      if form
        res << [workload_button(@event, align: "left", cols: 3)] if @event.id
      else
        res << [workload_button(@event, align: "left", cols: 4), {kind: "gap", size: 1}, {kind: "link", icon: "attendance.svg", label: I18n.t("calendar.attendance"), url: attendance_event_path, frame: "modal", align: "left", cols: 2}]
        res << [{kind: "gap", size:1, cols: 6, class: "text-xs"}]
        res << [{kind: "side-cell", value: I18n.t("target.abbr"),rows: 2}, {kind: "top-cell", value: I18n.t("target.focus.def_a")}, {kind: "lines", value: @event.def_targets, cols: 5}]
        res << [{kind: "top-cell", value: I18n.t("target.focus.ofe_a")}, {kind: "lines", class: "align-top border px py", value: @event.off_targets, cols: 5}]      end
    end

    # return icon and top of FieldsComponent for Tasks
    def task_title(title)
      res = event_title(@event.title(show: true), subtitle: title, cols: 3)
    end

    # complete event title with top-right corner elements
    def top_right_title(res, form)
      if form # top right corner of title
        res[0] << {kind: "icon", value: "calendar.svg"}
        res[0] << {kind: "date-box", key: :start_date, s_year: @event.team_id > 0 ? @event.team.season.start_date : @event.start_date, e_year: @event.team_id > 0 ? @event.team.season.end_year : nil, value: @event.start_date}
        unless @event.rest? # add start_time inputs
          res[1] << {kind: "icon", value: "clock.svg"}
          res[1] << {kind: "time-box", key: :hour, hour: @event.hour, min: @event.min}
        end
        res.last << {kind: "hidden", key: :season_id, value: @season.id} if @event.team.id==0
        res.last << {kind: "hidden", key: :team_id, value: @event.team_id}
        res.last << {kind: "hidden", key: :kind, value: @event.kind}
      else
        res[0] << {kind: "icon-label", icon: "calendar.svg", value: @event.date_string}
        res[1] << {kind: "icon-label", icon: "clock.svg", value: @event.time_string} unless @event.rest?
      end
    end

    # return FieldsComponent @fields for show_training
    def show_training_fields
      res = [[{kind: "accordion", title: I18n.t("task.many"), tail: "#{I18n.t("stat.total")}:" + " " + @event.work_duration, objects: task_accordion(@event)}]]
    end

    def show_match_fields
      res = [[
        {kind: "gap", size: 2},
        {kind: "top-cell", value: @event.score[:home][:team]},
        {kind: "label", value: @event.score[:home][:points], class: "border px py"},
        {kind: "gap"}
        ]]
      res << [
        {kind: "gap", size: 2},
        {kind: "top-cell", value: @event.score[:away][:team]},
        {kind: "label", value: @event.score[:away][:points], class: "border px py"},
        {kind: "gap"}
      ]
      res << [{kind: "gap", size: 1, cols: 4, class: "text-xs"}]
      res << [{kind: "gap", size: 2}, {kind: "side-cell", value: I18n.t("player.many"), align: "left", cols: 3}]
      res << [{kind: "gap", size: 2}, {kind: "grid", value: period_grid(@event.periods), cols: 3}]
      res
    end

    # return FieldsComponent for match form
    def match_form_fields
      score   = @event.score(0)
      periods = @event.periods
      res     = [[{kind: "side-cell", value: I18n.t("team.home_a"), rows: 2}, {kind: "radio-button", key: :home, value: true, checked: @event.home, align: "right", class: "align-center"}, {kind: "top-cell", value: @event.team.to_s}, {kind: "number-box", key: :p_for, min: 0, max: 200, size: 3, value: score[:home][:points]}]]
      res << [{kind: "radio-button", key: :home, value: false, checked: @event.home==false, align: "right", class: "align-center"}, {kind: "text-box", key: :name, value: @event.name}, {kind: "number-box", key: :p_opp, min: 0, max: 200, size: 3, value: score[:away][:points]}]
      res << [{kind: "gap", size: 1, class: "text-xs"}]
      res << [{kind: "side-cell", value: I18n.t("player.many"), align:"left", cols: 3}]
      if periods
        grid = period_grid(periods, edit: true)
      else
        grid = player_grid(players: @event.players.order(:number), obj: @event.team)
      end
        res << [{kind: "gap", size:2}, {kind: "grid", value: grid, cols: 4}]
      res
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
    def task_form_fields(view_url=nil)
      if @drill
        @description = [[
          {kind: "string", value: @drill.explanation.empty? ? @drill.description : @drill.explanation}
        ]]
      else
        @description = nil
      end
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
          {kind: "select-load", key: :drill_id, url: view_url, options: @drills, value: @drill ? @drill.id : nil, hidden: @task.id},
          {kind: "number-box", key: :duration, min: 1, max: 90, size: 3, value: @task.duration}
        ],
        [
          {kind: "hidden", key: :task_id, value: @task.id},
          {kind: "hidden", key: :order, value: @task.order},
          {kind: "hidden", key: :retlnk, value: @retlnk}
        ]
      ]
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
#           task.drill.targets.each {|target|
#            t_name = target.concept
#            data[t_name] = data[t_name] ? data[t_name] + task.duration : task.duration if target.priority==1
#          }
        end
      }
      {title: title, data: data}
    end

    def rebuild_event(event_params)
      @event   = Event.new unless @event
      e_params = event_params
      @event.start_time = e_params[:start_date] if e_params[:start_date]
      @event.hour       = e_params[:hour].to_i if e_params[:hour]
      @event.min        = e_params[:min].to_i if e_params[:min]
      @event.duration   = e_params[:duration].to_i if e_params[:duration]
      @event.name       = e_params[:name] if e_params[:name]
      @event.p_for      = e_params[:p_for].to_i if e_params[:p_for]
      @event.p_opp      = e_params[:p_opp].to_i if e_params[:p_opp]
      @event.location_id= e_params[:location_id].to_i if e_params[:location_id]
      @event.home       = e_params[:home] if e_params[:home]
      check_stats(params[:stats]) if params[:stats]
      check_targets(e_params[:event_targets_attributes]) if e_params[:event_targets_attributes]
      if e_params[:tasks_attributes]  # updated tasks in session edit form
        check_tasks(e_params[:tasks_attributes])
      elsif e_params[:task] # updated task from edit_task_form (add or edit)
        check_task(e_params[:task])
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

    # grid to plan playing time dependiong on time rules
    def period_grid(periods, edit: nil)
      head = [{kind: "normal", value: I18n.t("player.number"), align: "center"}, {kind: "normal", value: I18n.t("person.name")}]
      rows    = []
      e_stats = @event.stats
      1.upto(periods[:total]) {|i| head << {kind: "normal", value: "Q#{i.to_s}"}} if periods
      @event.players.order(:number).each{|player|
        p_stats = Stat.by_player(player.id, e_stats)
        row = {url: player_path(player), frame: "modal", items: []}
        row[:items] << {kind: "normal", value: player.number, align: "center"}
        row[:items] << {kind: "normal", value: player.to_s}
        if periods
          1.upto(periods[:total]) { |q|
            q_stat = Stat.by_q(q, p_stats).first
            if edit
              row[:items] << {kind: "checkbox-q", key: :stats, player_id: player.id, q: "q#{q}", value: q_stat ? q_stat[:value] : 0, align: "center"}
            else
              row[:items] << ((q_stat and q_stat[:value]==1) ? {kind: "icon", value: "Yes.svg"} : {kind: "gap", size: 1, class: "border px py"})
            end
          }
        end
        rows << row
      }
      {title: head, rows: rows}
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
        @task          = (t_dat[:task_id] and t_dat[:task_id]!="") ? Task.find(t_dat[:task_id]) : Task.new(event_id: @event.id)
        @task.order    = t_dat[:order].to_i if t_dat[:order]
        @task.drill_id = t_dat[:drill_id] ? t_dat[:drill_id].to_i : params[:task][:drill_id].split("|")[0].to_i
        @task.duration = t_dat[:duration].to_i if t_dat[:duration]
        @task.remarks  = t_dat[:remarks] if t_dat[:remarks]
        @task.save
      end
    end

    # check stats added to event
    def check_stats(s_params)
      e_stats = @event.stats
      s_params.each {|s_param|
        s_arg = s_param[0].split("_")
        stat = Stat.fetch(event_id: @event.id, player_id: s_arg[0].to_i, concept: s_arg[1], stats: e_stats)
        if stat # just update the value
          stat[:value] = s_param[1].to_i
        else  # create a new stat
          e_stats << Stat.new(event_id: @event.id, player_id: s_arg[0].to_i, concept: s_arg[1], value: s_param[1].to_i)
        end
      }
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
        t("rest.created") + "#{@event.to_s}"
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
        t("rest.updated") + "#{@event.to_s}"
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
        t("rest.deleted") + "#{@event.to_s}"
      when :train
        t("train.deleted") + "#{@event.date_string}"
      when :match
        t("match.deleted") + "#{@event.to_s(true)}"
      end
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
