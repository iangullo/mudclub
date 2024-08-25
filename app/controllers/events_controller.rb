# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
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
class EventsController < ApplicationController
	include Filterable
	include PdfGenerator
	before_action :set_event, only: %i[ show edit add_task show_task edit_task task_drill player_stats edit_player_stats load_chart attendance copy update destroy ]

	# GET /events or /events.json
	def index
		club  = Club.find_by_id(@clubid) if @clubid
		team  = Team.find_by_id(@teamid) if @teamid
		if check_access(obj: team || club)
			get_event_context
			start_date = (params[:start_date] ? params[:start_date] : Date.today.at_beginning_of_month).to_date
			season     = Season.find_by_id(@seasonid) || team&.season
			url        = (team ? team_events_path(team, start_date:) : club_events_path(@clubid, season_id: season&.id, start_date:))
			anchor     = {url:, rdx: @rdx}
			@title     = create_fields(helpers.event_index_title(team:, season:))
			@calendar  = CalendarComponent.new(anchor:, obj: (team || club), start_date:, user: current_user, create_url: new_event_path)
			retlnk     = (team ? team_path(team, rdx: @rdx) : club_path(@clubid, season_id: season&.id, rdx: @rdx))
			@submit    = create_submit(close: "back", submit: nil, retlnk:)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1 or /events/1.json
	def show
		if check_access(obj: @event)
			respond_to do |format|
				title = helpers.event_title_fields(cols: @event.train? ? 3 : nil)
				format.pdf do
					if u_manager? || u_coach?
						response.headers['Content-Disposition'] = "attachment; filename=drill.pdf"
						pdf = event_to_pdf(title)
						send_data pdf.render(filename: "#{@event.to_s}.pdf", type: "application/pdf")
					end
				end
				format.html do
					editor    = u_manager? || @event.team.has_coach(u_coachid)
					@title    = create_fields(title)
					player_id = params[:player_id].presence || u_playerid
					if @event.rest?
						submit  = edit_event_path(season_id: @seasonid, cal: @cal) if editor
						@submit = create_submit(submit:, frame: "modal")
					elsif @event.train? && @event.team.has_player(player_id)	# we want to check player stats for a training session
						redirect_to player_stats_event_path(@event, player_id:, rdx: @rdx, cal: @cal), data: {turbo_action: "replace"}
					else	# gotta be a coach or manager
						if @event.match?
							@fields = create_fields(helpers.match_show_fields)
							grid    = helpers.match_roster_grid
							@grid   = create_grid(grid[:data], controller: grid[:controller])
						else
							@targets = create_fields(helpers.training_target_fields)
							@fields  = create_fields(helpers.training_show_fields)
						end
						submit  = edit_event_path(season_id: @seasonid, rdx: @rdx, cal: @cal) if editor
						@submit = create_submit(close: "back", retlnk: get_retlnk, submit:)
					end
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/new
	def new
		get_event_context
		if check_access(obj: Team.find(@teamid) || Club.find(@clubid))
			@event  = Event.prepare(event_params)
			@season = (@event.team_id == 0) ? Season.search(@seasonid) : @event.team.season
			@sport  = @event.team.sport&.specific
			if @event
				if @event.rest? || @event.team.has_coach(u_coachid)
					prepare_event_form(new: true)
				else
					redirect_to(get_retlnk, data: {turbo_action: "replace"})
				end
			else
				redirect_to(get_retlnk, data: {turbo_action: "replace"})
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit
	def edit
		if check_access(obj: @event&.team)
			prepare_event_form(new: false)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /events or /events.json
	def create
		get_event_context
		e_data = event_params
		@event = Event.prepare(event_params)
		if check_access(obj: @event&.team || Club.find(@clubid))
			respond_to do |format|
				@event.rebuild(e_data)
				if @event.save
					prepare_update_redirect(e_data)
					link_holidays
					c_notice = helpers.event_create_notice
					modal    = @event.rest?
					register_action(:created, c_notice[:message], url: event_path(@event, rdx: 2), modal:)
					format.html { redirect_to @retlnk, notice: c_notice, data: {turbo_action: "replace"} }
					format.json { render :show, status: :created, location: @retlnk}
				else
					prepare_event_form(new: true)
					format.html { render :new, status: :unprocessable_entity }
					format.json { render json: @event.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /events/1 or /events/1.json
	def update
		if check_access(obj: @event&.team || Club.find(@clubid))
			respond_to do |format|
				e_data  = event_params
				url     = event_path(@event, rdx: @rdx)
				modal   = @event.rest?
				@player = Player.find_by_id(e_data[:player_id].presence)
				@event.rebuild(e_data)
				prepare_update_redirect(e_data)
				if e_data[:player_ids].present?	# updated attendance
					changed = check_attendance(e_data[:player_ids])
				elsif e_data[:task].present? # updated task from edit_task_form
					changed = check_task(e_data[:task])
					@notice = @notice + @task.to_s if changed
				else	# it is an event update attempt
					seek_duplicate_event(e_data) if e_data[:copy].presence
					if @event.modified?	# do we need to save?
						if @event.save
							changed = true
							@retlnk = event_path(@event, rdx: @rdx, cal: @cal)	
							@event.tasks.reload if e_data[:tasks_attributes] # a training session
						else
							prepare_event_form(new: false)	# continue editing, it did not work
							format.html { render :edit, status: :unprocessable_entity }
							format.json { render json: @event.errors, status: :unprocessable_entity }
						end
					end
					changed = (check_stats(param_passed(:event, :stats_attributes)&.values&.first) || changed)
					changed = (check_stats(params[:outings]) || changed)
				end
				@notice = helpers.event_update_notice(@notice, changed:)
				register_action(:updated, @notice[:message], url: event_path(rdx: 2)) if changed && !e_data[:task].present?
				format.html { redirect_to @retlnk, notice: @notice, data: {turbo_action: "replace"}}
				format.json { render @retview, status: :ok, location: @retlnk }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /events/1 or /events/1.json
	def destroy
		if check_access(obj: @event&.team || Club.find(@clubid))
			team   = @event.team
			@event.destroy
			respond_to do |format|
				next_url = team.id > 0 ? team : events_path
				next_act = team.id > 0 ? :show : :index
				a_desc   = helpers.event_delete_notice
				register_action(:deleted, a_desc[:message])
				format.html { redirect_to next_url, action: next_act.to_sym, status: :see_other, notice: a_desc, data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/attendance
	def attendance
		if @event && check_access(action: :update, obj: @event.team)
			@title  = create_fields(helpers.event_attendance_title)
			@fields = create_fields(helpers.event_attendance_form_fields)
			@submit = create_submit(retlnk: event_path(@event, rdx: @rdx))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /events/1/copy
	def copy
		if check_access(action: :create, obj: Club.find(@clubid))
			@season = Season.latest
			@teams  = get_teams
			if @teams	# we have some teams we can copy to
				@fields = create_fields(helpers.event_copy_fields)
				@submit = create_submit
			else
				notice  = helpers.flash_message("#{I18n.t("team.none")} ", "info")
				redirect_to event_path(@event, rdx: @rdx), notice:, data: {turbo_action: "replace"}
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/add_task
	def add_task
		if @event && check_access(action: :update, obj: @event.team)
			prepare_task_form(subtitle: I18n.t("task.add"), retlnk: edit_event_path(@event), search_in: add_task_event_path(@event))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit_task
	def edit_task
		if @event && check_access(action: :update, obj: @event.team)
			prepare_task_form(subtitle: I18n.t("task.edit"), retlnk: edit_event_path(@event), search_in: edit_task_event_path(@event), task_id: true)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/show_task
	def show_task
		if check_access(action: :show, obj: @event)
			@task   = Task.find(params[:task_id])
			@fields = create_fields(helpers.task_show_fields(task: @task, team: @event.team))
			@submit = create_submit(close: "back", retlnk: :back, submit: (u_manager? or @event.team.has_coach(u_coachid)) ? edit_task_event_path(task_id: @task.id) : nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/load_chart
	def load_chart
		if check_access(action: :show, obj: @event)
			header = helpers.event_title_fields(cols: @event.train? ? 3 : nil, chart: true)
			@chart = ModalPieComponent.new(header:, chart: helpers.event_workload(name: params[:name]))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/player_stats?player_id=X
	def player_stats
		@player = Player.real.find_by_id(params[:player_id] ? params[:player_id] : u_playerid)
		if check_access(action: :show, obj: @event)
			unless @event.rest?	# not keeing stats for holidays ;)
				if @event.has_player(@player&.id)	# we do have a player
					@title  = create_fields(helpers.event_title_fields(cols: @event.train? ? 3 : nil))
					@fields = create_fields(helpers.event_player_stats_fields)
					editor  = (u_manager? || @event.team.has_coach(u_coachid) || @event.team.has_player(u_playerid))
					@submit = create_submit(submit: @player ? edit_player_stats_event_path(@event, player_id: u_playerid) : nil, frame: "modal")
				else
					redirect_to team_path(@event.team, rdx: @rdx), data: {turbo_action: "replace"}
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit_player_stats?player_id=X
	def edit_player_stats
		if check_access(action: :edit, obj: @event)
			unless @event.rest?	# not keeing stats for holidays ;)
				@player = Player.find_by_id(params[:player_id] ? params[:player_id] : u_playerid)
				if @player&.id.to_i > 0	# we do have a player
					@title  = create_fields(helpers.event_title_fields(cols: @event.train? ? 3 : nil))
					@fields = create_fields(helpers.event_edit_player_stats_fields)
					@submit = create_submit
				else
					redirect_to team_path(@event.team, rdx: @rdx), data: {turbo_action: "replace"}
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# check attendance
		def check_attendance(p_array)
			changed   = nil	# first pass
			attendees = Array.new	# array to include all player_ids
			p_array.each {|p| attendees <<  Player.find(p.to_i) unless (p=="" or p.to_i==0)}

			attendees.each do |player|	# second pass - manage associations
				unless @event.has_player(player.id)
					changed ||= true
					@event.players << player
				end
			end

			@event.players.each do |player|	# cleanup removed attendances
				unless attendees.include?(player)
					changed ||= true
					@event.players.delete(player)
				end
			end
			return changed
		end

		# check stats - a single player updating an event
		def check_stats(stats)
			@sport.parse_stats(@event, stats) if stats	# lets_ check them
		end

		# ensure a task is correctly added to event
		def check_task(t_dat)
			if t_dat  # we are adding a single task
				@task          = t_dat[:task_id].present? ? Task.find(t_dat[:task_id]) : Task.new(event_id: @event.id)
				@task.order    = t_dat[:order].to_i if t_dat[:order]
				@task.drill_id = t_dat[:drill_id] ? t_dat[:drill_id].to_i : params[:task][:drill_id].split("|")[0].to_i
				@task.duration = t_dat[:duration].to_i if t_dat[:duration]
				@task.remarks  = t_dat[:remarks] if t_dat[:remarks]
				@task.save
			end
		end

		# pdf export of @event content
		def event_to_pdf(header)
			p_title = header.take(2)
			p_title[0][1][:cols] = 1
			p_title[1][0][:cols] = 1
			footer = "#{@event.team.to_s} #{@event.date_string}"
			pdf    = pdf_create(header: p_title, footer:)#, full_width: true)
			if @event.kind == "train"
				pdf_label_text(label: I18n.t("target.many"), text: @event.print_targets)
				pdf_separator_line(style: "empty")
				@event.tasks.each do |task|
					pdf_subtitle(task.headstring)
					pdf_rich_text(task.drill.explanation) if task.drill.explanation&.present?
					pdf_rich_text(task.remarks) if task.remarks&.present?
					pdf_separator_line(style: "empty")
				end
				pdf_new_page
				pdf_subtitle(I18n.t("calendar.attendance"))
				@event.team.players.order(:number).each do |player|
					pdf_label_text(label: player.to_s(style: 3), text: "_")
				end
				pdf_separator_line(style: "empty")
				pdf_subtitle(I18n.t("task.remarks"))
			end
			pdf
		end

		# try to establish where we've been called from...
		def get_event_context
			@cal      = get_param(:cal)
			@seasonid = p_seasonid
			@teamid   = p_teamid
			@teamid ||= @event&.team_id if @event&.team_id.to_i > 0
		end

		# return array of valid team options for a selector
		def get_teams
			teams = (u_manager? ? u_club.teams.for_season(@season.id) : current_user.coach.team_list(season_id: @season.id))
			opts  = []
			teams.each do |team|
				opts << {id: team.id, name: team.nick}
			end
			return opts
		end

		# determine the right retlnk
		def get_retlnk
			if @cal && @event	# return to a calendar view
				sdate = @event.start_date
				return team_events_path(@event.team_id, start_date: sdate, cal: true) if @event&.team_id>0	# coming froma team calendar event view
				return season_events_path(@event.team.season_id, start_date: sdate, cal: true) if @seasonid	# it's a season calendar
				return "/"	# failsafe
			elsif @rdx&.to_i == 2	# called from a server log view
				return home_log_path
			else
				return team_path(id: @teamid, rdx: @rdx) if @teamid
				return season_path(id: @seasonid, rdx: @rdx) if @seasonid
				return "/"
			end
		end

		# determine task/drill objects from params received
		def get_task(load_drills: nil)
			if params[:event]
				t_param = event_params[:task]
			elsif params[:task] # comes from a dynamic refresh
				tmp     = params[:task][:drill_id]&.split("|")
				t_param = {drill_id: tmp[0], task_id: tmp[1]}
			else
				t_param = params
			end
			@task = t_param[:task_id] ? Task.find(t_param[:task_id]) : Task.new(event: @event, order: @event.tasks.count + 1, duration: 5)
			if load_drills
				@drills = filter!(Drill).pluck(:name, :id, :coach_id)
				@drills = Drill.where(kind_id: @task.drill&.kind_id).pluck(:name, :id, :coach_id) if @drills.empty? && @task
				@drill  = t_param[:drill_id] ? Drill.find(t_param[:drill_id]) : (@task.drill ? @task.drill : @drills.size>0 ? Drill.find(@drills.first[1]) : nil)
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

		# prepare new/edit event form
		def prepare_event_form(new: nil)
			@title = create_fields(helpers.event_title_fields(form: true, cols: @event.match? ? 2 : nil))
			if @event.match?
				@fields  = create_fields(helpers.match_form_fields(new:))
				unless new
					grid  = helpers.match_roster_grid(edit: true)
					@grid = create_grid(grid[:data], controller: grid[:controller])
				end
			end
			unless new # editing
				unless @event.rest?
					r_lnk = event_path(@event, rdx: @rdx, cal: @cal)
					if @event.train?
						@btn_add = create_button({kind: "add", label: I18n.t("task.add"), url: add_task_event_path(rdx: @rdx)}) if (u_manager? || @event.team.has_coach(u_coachid))
						@drills  = @event.drill_list
					end
					@submit = create_submit(close: "back", retlnk: r_lnk)
				end
			end
			@submit ||= create_submit(retlnk: @retlnk)
		end

		# prepare edit/add task form
		def prepare_task_form(subtitle:, retlnk:, search_in:, task_id: nil)
			get_task(load_drills: true) # get the right @task/@drill
			scratch      = task_id.nil?
			title        = helpers.event_task_title(subtitle:)
			title       << helpers.drill_search_bar(search_in:, task_id: @task.id, scratch:, cols: 4)
			@title       = create_fields(title)
			@fields      = create_fields(helpers.task_form_fields(search_in:))
			@description = helpers.task_form_description
			@remarks     = create_fields(helpers.task_form_remarks)
			@submit      = create_submit(retlnk: :back)
		end

		# establish redirection & notice for based on update kind
		def prepare_update_redirect(e_data)
			if e_data[:task].present?
				@notice  = I18n.t("task.updated")
				@retview = :edit
				@retlnk  = edit_event_path(@event, rdx: @rdx, cal: @cal)
			elsif params[:event].present?
				@retview = :show
				if @cal || @event.rest? #--> Calendar view
					if @event.team_id.to_i > 0 # team events
						@retlnk = team_events_path(@event.team, start_date: @event.start_date, rdx: @rdx, cal: true)
					else
						@retlnk = season_events_path(@event.start_date, start_date: @event.start_date, rdx: @rdx, cal: true)
					end
				else
					@retlnk = event_path(@event, rdx: @rdx, cal: @cal) unless @event.rest?
				end
				if @event.modified?
					@notice = I18n.t("#{@event.kind}.updated")
				elsif	e_data[:player_ids].present?	# players to partcipate
					@notice = I18n.t("#{@event.kind}.att_check")
				elsif params[:event][:stats_attributes].present? || params[:outings].present?	# updated stats/outings
					@notice = I18n.t("stat.updated")
				else
					@notice = I18n.t("status.no_data")
				end
			end
		end

		# when copying an event, need to avoid duplicates, checking if an Event
		# exists for the same date/time/team and reload if needed
		def seek_duplicate_event(e_data)
			e_search            = @event.dup	# prepare to search
			e_search.team_id    = e_data[:team_id].presence
			e_search.start_time = e_data[:start_date].presence
			e_search.hour       = e_data[:hour].presence
			e_search.min        = e_data[:min].presence
			e_copy              = e_search.dup
			e_search            = Event.where(start_time: e_search.start_time, team_id: e_search.team_id).first
			e_copy              = e_search if e_search	# copy destination set
			unless e_copy.id == @event.id	# manage task/target bindings unless it is the same destination
				e_copy.save unless e_copy.id	# save if it's a new event
				e_copy.duration = @event.duration
				e_copy.targets.delete_all
				@event.targets.each {|target| e_copy.targets << target.dup}	# copy targets
				e_copy.tasks.delete_all
				@event.tasks.each {|task| e_copy.tasks << task.dup}	# copy tasks
				@event          = e_copy
			end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_event
			@event    = Event.find_by_id(params[:id])
			@sport    = @event&.team&.sport&.specific
			get_event_context
		end

		# Only allow a list of trusted parameters through.
		def event_params
			params.require(:event).permit(
					:id,
					:cal,
					:club_id,
					:copy,
					:drill_id,
					:duration,
					:end_time,
					:name,
					:kind,
					:hour,
					:kind_id,
					:location_id,
					:min,
					:p_for,
					:p_opp,
					:player_id,
					:rdx,
					:start_date,
					:start_time,
					:skill_id,
					:task_id,
					:team_id,
					:season_id,
					outings: {},
					event_targets_attributes: [:id, :priority, :event_id, :target_id, :_destroy, target_attributes: [:id, :focus, :aspect, :concept]],
					player_ids: [],
					stats_attributes: [],
					task: [:id, :task_id, :order, :drill_id, :duration, :remarks, :retlnk],
					tasks_attributes: [:id, :order, :drill_id, :duration, :remarks, :_destroy]
				)
		end
end
