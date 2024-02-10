# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
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
	before_action :set_event, only: %i[ show edit add_task show_task edit_task task_drill player_stats edit_player_stats load_chart attendance copy update destroy ]

	# GET /events or /events.json
	def index
		if check_access(roles: [:user])
			start_date = (params[:start_date] ? params[:start_date] : Date.today.at_beginning_of_month).to_date
			events     = Event.search(params)
			team       = Team.find(params[:team_id]) if params[:team_id]
			season     = events.empty? ? Season.last : events.first.team.season
			@retlnk  ||= team ? team_events_path(team, start_date:) : (season ? season_events_path(season, start_date:) : events_path)
			@title     = create_fields(helpers.event_index_title(team: team, season: season))
			@calendar  = CalendarComponent.new(start_date:, events:, anchor: @retlnk, obj: team ? team : season, user: current_user, create_url: new_event_path)
			@submit    = create_submit(close: "back", submit: nil, close_return: team ? team_path(team) : seasons_path(season_id: season.id))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1 or /events/1.json
	def show
		if check_access(roles: [:manager, :coach], obj: @event.team)
			@title    = create_fields(helpers.event_title_fields(cols: @event.train? ? 3 : nil))
			player_id = params[:player_id].presence || u_playerid
			if @event.rest?
				@submit = create_submit(submit: (u_manager? or @event.team.has_coach(u_coachid)) ? edit_event_path(season_id: params[:season_id]) : nil, frame: "modal")
			elsif @event.train? && @event.team.has_player(player_id)	# we want to check player stats for a training session
				redirect_to player_stats_event_path(@event, player_id:), data: {turbo_action: "replace"}
			else	# gotta be a coach or manager
				@retlnk ||= team_path(@event.team)
				if @event.match?
					@fields = create_fields(helpers.match_show_fields)
					grid    = helpers.match_roster_grid
					@grid   = create_grid(grid[:data], controller: grid[:controller])
				else
					@fields = create_fields(helpers.training_show_fields)
				end
				@submit = create_submit(close: "back", close_return: @retlnk, submit: (u_manager? or @event.team.has_coach(u_coachid)) ? edit_event_path(retlnk: @retlnk) : nil)
			end
		else
			redirect_to @retlnk || events_path, data: {turbo_action: "replace"}
		end
	end

	# GET /events/new
	def new
		if check_access(roles: [:manager, :coach])
			@event  = Event.prepare(event_params)
			@season = (@event.team_id == 0) ? Season.search(event_params[:season_id]) : @event.team.season
			@sport  = @event.team.sport&.specific
			if @event
				if @event.rest? or (@event.team_id >0 and @event.team.has_coach(u_coachid))
					prepare_event_form(new: true)
				else
					redirect_to(u_manager? ? "/slots" : @event.team)
				end
			else
				redirect_to(u_manager? ? "/slots" : "/", data: {turbo_action: "replace"})
			end
		else
			redirect_to get_retlnk, data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit
	def edit
		if check_access(roles: [:manager]) || @event.team.has_coach(u_coachid)
			prepare_event_form(new: false)
		else
			redirect_to @retlnk || team_events_path(team_id: @event.team.id, start_date: @event.start_date), data: {turbo_action: "replace"}
		end
	end

	# POST /events or /events.json
	def create
		@event = Event.prepare(event_params)
		if check_access(roles: [:manager]) || @event.team.has_coach(u_coachid)
			respond_to do |format|
				@event.rebuild(event_params)
				if @event.save
					link_holidays
					c_notice = helpers.event_create_notice
					modal    = @event.rest?
					register_action(:created, c_notice[:message], url: event_path(@event, retlnk: home_log_path), modal:)
					format.html { redirect_to @event.team_id > 0 ? team_events_path(@event.team, start_date: @event.start_date) : events_path(start_date: @event.start_date), notice: c_notice, data: {turbo_action: "replace"} }
					format.json { render :show, status: :created, location: events_path}
				else
					prepare_event_form(new: true)
					format.html { render :new, status: :unprocessable_entity }
					format.json { render json: @event.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to get_retlnk, data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /events/1 or /events/1.json
	def update
		if check_access(roles: [:manager]) || @event.team.has_coach(u_coachid)
			respond_to do |format|
				e_data  = event_params
				url     = event_path(@event, retlnk: @retlnk)
				modal   = @event.rest?
				@player = Player.find_by_id(e_data[:player_id].presence)
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
				register_action(:updated, @notice[:message], url: event_path(retlnk: home_log_path)) if changed && !e_data[:task].present?
				format.html { redirect_to @retlnk, notice: @notice, data: {turbo_action: "replace"}}
				format.json { render @retview, status: :ok, location: @retlnk }
			end
		else
			redirect_to (@retlnk || events_path), data: {turbo_action: "replace"}
		end
	end

	# DELETE /events/1 or /events/1.json
	def destroy
		if check_access(roles: [:manager]) || @event.team.has_coach(u_coachid)
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
			redirect_to (@retlnk || events_path), data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/show_task
	def show_task
		if check_access(roles: [:manager, :coach])
			@task   = Task.find(params[:task_id])
			@fields = create_fields(helpers.task_show_fields(task: @task, team: @event.team))
			@submit = create_submit(close: "back", close_return: :back, submit: (u_manager? or @event.team.has_coach(u_coachid)) ? edit_task_event_path(task_id: @task.id) : nil)
		else
			redirect_to (@retlnk || events_path), data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/add_task
	def add_task
		if @event && (check_access(roles: [:manager]) || @event.team.has_coach(u_coachid))
			prepare_task_form(subtitle: I18n.t("task.add"), retlnk: edit_event_path(@event), search_in: add_task_event_path(@event))
		else
			redirect_to (@retlnk || events_path), data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit_task
	def edit_task
		if check_access(roles: [:manager]) || @event.team.has_coach(u_coachid)
			prepare_task_form(subtitle: I18n.t("task.edit"), retlnk: edit_event_path(@event), search_in: edit_task_event_path(@event), task_id: true)
		else
			redirect_to (@retlnk || events_path), data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/load_chart
	def load_chart
		if check_access(roles: [:manager, :coach])
			header = helpers.event_title_fields(cols: @event.train? ? 3 : nil, chart: true)
			@chart = ModalPieComponent.new(header:, chart: helpers.event_workload(name: params[:name]))
		else
			redirect_to @retlnk || event_path(@event), data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/attendance
	def attendance
		if check_access(roles: [:manager, :coach], obj: @event)
			@title  = create_fields(helpers.event_attendance_title)
			@fields = create_fields(helpers.event_attendance_form_fields)
			@submit = create_submit(close_return: event_path(@event, retlnk: @retlnk))
		else
			redirect_to @retlnk || event_path(@event), data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/player_stats?player_id=X
	def player_stats
		@player = Player.real.find_by_id(params[:player_id] ? params[:player_id] : u_playerid)
		if check_access(roles: [:manager, :coach], obj: @player)
			unless @event.rest?	# not keeing stats for holidays ;)
				if @event.has_player(@player&.id)	# we do have a player
					@title  = create_fields(helpers.event_title_fields(cols: @event.train? ? 3 : nil))
					@fields = create_fields(helpers.event_player_stats_fields)
					editor  = (u_manager? || @event.team.has_coach(u_coachid) || @event.team.has_player(u_playerid))
					@submit = create_submit(submit: @player ? edit_player_stats_event_path(@event, player_id: u_playerid) : nil, frame: "modal")
				else
					redirect_to @retlnk || team_path(@event.team), data: {turbo_action: "replace"}
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit_player_stats?player_id=X
	def edit_player_stats
		if check_access(roles: [:manager], obj: @event)
			unless @event.rest?	# not keeing stats for holidays ;)
				@player = Player.find_by_id(params[:player_id] ? params[:player_id] : u_playerid)
				if @player&.id.to_i > 0	# we do have a player
					@title  = create_fields(helpers.event_title_fields(cols: @event.train? ? 3 : nil))
					@fields = create_fields(helpers.event_edit_player_stats_fields)
					@submit = create_submit
				else
					redirect_to @retlnk || team_path(@event.team), data: {turbo_action: "replace"}
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /events/1/copy
	def copy
		if check_access(roles: [:manager, :coach])
			@season = Season.latest
			@teams  = u_manager? ? Team.for_season(@season.id) : current_user.coach.team_list
			if @teams	# we have some teams we can copy to
				@fields = create_fields(helpers.event_copy_fields)
				@submit = create_submit(close_return: @retlnk)
			else
				notice  = helpers.flash_message("#{I18n.t("team.none")} ", "info")
				redirect_to @retlnk || event_path(@event), notice:, data: {turbo_action: "replace"}
			end
		else
			redirect_to @retlnk || events_path, data: {turbo_action: "replace"}
		end
	end

	private
		# establish redirection & notice for based on update kind
		def prepare_update_redirect(e_data)
			@event.rebuild(e_data)
			if e_data[:task].present?
				@notice  = I18n.t("task.updated")
				@retview = :edit
				@retlnk  = edit_event_path(@event, retlnk: @retlnk)
			elsif params[:event].present?
				@retview = :show
				@retlnk  = event_path(@event, retlnk: @retlnk) unless @event.rest?
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
					r_lnk = event_path(@event, retlnk: @retlnk)
					if @event.train?
						@btn_add = create_button({kind: "add", label: I18n.t("task.add"), url: add_task_event_path(retlnk: r_lnk)}) if (u_manager? || @event.team.has_coach(u_coachid))
						@drills  = @event.drill_list
					end
					@submit = create_submit(close: "back", close_return: r_lnk)
				end
			end
			@submit ||= create_submit(close_return: @retlnk)
		end

		# prepare edit/add task form
		def prepare_task_form(subtitle:, retlnk:, search_in:, task_id: nil)
			get_task(load_drills: true) # get the right @task/@drill
			title        = helpers.event_task_title(subtitle:)
			title       << helpers.drill_search_bar(search_in:, task_id: (task_id ? @task.id : nil), scratch: true, cols: 4)
			@title       = create_fields(title)
			@fields      = create_fields(helpers.task_form_fields(search_in:, retlnk:))
			@description = helpers.task_form_description
			@remarks     = create_fields(helpers.task_form_remarks)
			@submit      = create_submit(close_return: :back)
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
			@task   = t_param[:task_id] ? Task.find(t_param[:task_id]) : Task.new(event: @event, order: @event.tasks.count + 1, duration: 5)
			if load_drills
				@drills = filter!(Drill).pluck(:name, :id, :coach_id)
				@drill  = t_param[:drill_id] ? Drill.find(t_param[:drill_id]) : (@task.drill ? @task.drill : @drills.size>0 ? Drill.find(@drills.first[1]) : nil)
			end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_event
			@event  = Event.find_by_id(params[:id])
			@sport  = @event&.team&.sport&.specific
			@retlnk = get_retlnk
		end

		# determine the right retlnk
		def get_retlnk
			if params[:retlnk].present?
				retlnk = params[:retlnk].presence
			elsif params[:event].present?
				if event_params[:retlnk].present?
					retlnk = event_params[:retlnk].presence
				elsif params[:task].present?
					retlnk = event_params[:task][:retlnk].presence
				end
			elsif params[:season_id].present?
				retlnk = params[:season_id].presence
			end

			if retlnk
				return safelink(retlnk)
			else
				return (@event.team and @event.team_id > 0) ? team_path(@event.team) : season_path(@event.team.season)
			end
		end

		# Sanitize retlink input
		def safelink(lnk=nil, team: nil)
			vlinks = [seasons_path, events_path, home_log_path]
			if @event
				vlinks += [
					event_path(@event),
					copy_event_path(@event),
					edit_event_path(@event),
					events_path(team_id: @event.team.id, start_date: @event.start_date.beginning_of_month, retlnk: team_path(@event.team)),
					team_path(@event.team),
					team_events_path(@event.team, start_date: @event.start_date.beginning_of_month),
					season_path(@event.team.season),
					season_events_path(@event.team.season, start_date: @event.start_date.beginning_of_month)
				]
			end
			vlinks << team_path(team) if team
			if (sdate = valid_date(lnk))
				vlinks << team_events_path(@event.team, start_date: sdate)
				vlinks << season_events_path(@event.team.season, start_date: sdate)
			end
			@retlnk = validate_link(lnk, vlinks)
		end

		# Only allow a list of trusted parameters through.
		def event_params
			params.require(:event).permit(
					:id,
					:copy,
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
					:player_id,
					:retlnk,
					outings: {},
					player_ids: [],
					stats_attributes: [],
					event_targets_attributes: [:id, :priority, :event_id, :target_id, :_destroy, target_attributes: [:id, :focus, :aspect, :concept]],
					task: [:id, :task_id, :order, :drill_id, :duration, :remarks, :retlnk],
					tasks_attributes: [:id, :order, :drill_id, :duration, :remarks, :_destroy]
				)
		end
end
