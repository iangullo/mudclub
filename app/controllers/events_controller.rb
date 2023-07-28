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
	before_action :set_event, only: %i[ show edit add_task show_task edit_task task_drill player_stats edit_player_stats load_chart attendance update destroy ]

	# GET /events or /events.json
	def index
		if check_access(roles: [:user])
			start_date = (params[:start_date] ? params[:start_date] : Date.today.at_beginning_of_month).to_date
			events     = Event.search(params)
			team       = Team.find(params[:team_id]) if params[:team_id]
			season     = events.empty? ? Season.last : events.first.team.season
			curlnk     = team ? team_events_path(team, start_date:) : (season ? season_events_path(season, start_date:) : events_path)
			@title     = create_fields(helpers.event_index_title(team: team, season: season))
			@calendar  = CalendarComponent.new(start_date:, events:, anchor: curlnk, obj: team ? team : season, user: current_user, create_url: new_event_path)
			@submit    = create_submit(close: "back", submit: nil, close_return: team ? team_path(team) : seasons_path(season_id: season.id))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1 or /events/1.json
	def show
		if check_access(roles: [:manager, :coach], obj: @event.team)
			@title = create_fields(helpers.event_title_fields(cols: @event.train? ? 3 : nil))
			if @event.rest?
				@submit = create_submit(submit: (u_manager? or @event.team.has_coach(u_coachid)) ? edit_event_path(season_id: params[:season_id]) : nil, frame: "modal")
			elsif current_user.player?
				player_id = params[:player_id].presence || u_playerid
				redirect_to stats_event_path(@event, player_id:), data: {turbo_action: "replace"}
			else
				retlnk  = params[:retlnk].presence || team_path(@event.team)
				if @event.match?
					@fields = create_fields(helpers.match_show_fields)
					@grid   = create_grid(helpers.match_roster_grid)
				else
					@fields = create_fields(helpers.training_show_fields)
				end
				@submit = create_submit(close: "back", close_return: retlnk, submit: (u_manager? or @event.team.has_coach(u_coachid)) ? edit_event_path(season_id: params[:season_id]) : nil)
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/new
	def new
		if check_access(roles: [:manager, :coach])
			@event = Event.prepare(event_params)
			@sport = @event.team.sport&.specific
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
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit
	def edit
		if check_access(roles: [:manager, :coach], obj: @event)
			prepare_event_form(new: false)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /events or /events.json
	def create
		@event = Event.prepare(event_params)
		if check_access(roles: [:manager, :coach], obj: @event)
			respond_to do |format|
				@event.rebuild(event_params)
				if @event.save
					link_holidays
					c_notice = helpers.event_create_notice
					register_action(:created, c_notice[:message])
					format.html { redirect_to @event.team_id > 0 ? team_events_path(@event.team, start_date: @event.start_date) : events_path(start_date: @event.start_date), notice: c_notice, data: {turbo_action: "replace"} }
					format.json { render :show, status: :created, location: events_path}
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
		if check_access(roles: [:manager, :coach], obj: @event)
			respond_to do |format|
				e_data  = event_params
				@player = Player.find_by_id(e_data[:player_id].presence)
				@event.rebuild(e_data)
				if prepare_update_redirect(e_data)	# prepare links to redirect
					if e_data[:player_ids].present?	# update attendance
						check_attendance(e_data[:player_ids])
						register_action(:updated, @notice[:message])
					elsif e_data[:stats_attributes] || params[:outings]
						check_stats(e_data[:stats_attributes], params[:outings])
						register_action(:updated, @notice[:message])
					elsif e_data[:task].present? # updated task from edit_task_form
						check_task(e_data[:task])
						@notice[:message] = @notice[:message] + @task.to_s
					end
					format.html { redirect_to @retlnk, notice: @notice, data: {turbo_action: "replace"}}
					format.json { render @retview, status: :ok, location: @retlnk }
				elsif @event.modified?	# do we need to save?
					if @event.save	# try to do it
						register_action(:updated, @notice[:message])
						@event.tasks.reload if e_data[:tasks_attributes] # a training session
						format.html { redirect_to @retlnk, notice: @notice, data: {turbo_action: "replace"}}
						format.json { render @retview, status: :ok, location: @retlnk }
					else
						prepare_event_form(new: false)	# continue editing, it did not work
						format.html { render :edit, status: :unprocessable_entity }
						format.json { render json: @event.errors, status: :unprocessable_entity }
					end
				else	# nothing to save
					format.html { redirect_to @retlnk, notice: @notice, data: {turbo_action: "replace"}}
					format.json { render @retview, status: :ok, location: @retlnk }
				end
			end
		else
			redirect_to events_path, data: {turbo_action: "replace"}
		end
	end

	# DELETE /events/1 or /events/1.json
	def destroy
		if check_access(roles: [:manager, :coach], obj: @event)
			team   = @event.team
			@event.destroy
			respond_to do |format|
				next_url = team.id > 0 ? team : events_path
				next_act = team.id > 0 ? :show : :index
				a_desc   = helpers.event_delete_notice
				register_action(:deleted, a_desc)
				format.html { redirect_to next_url, action: next_act.to_sym, status: :see_other, notice: a_desc, data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to events_path, data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/show_task
	def show_task
		if check_access(roles: [:manager, :coach])
			@task   = Task.find(params[:task_id])
			@fields = create_fields(helpers.task_show_fields(task: @task, team: @event.team))
			@submit = create_submit(close: "back", close_return: :back, submit: (u_manager? or @event.team.has_coach(u_coachid)) ? edit_task_event_path(task_id: @task.id) : nil)
		else
			redirect_to events_path, data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/add_task
	def add_task
		check_access(roles: [:manager], obj: @event)
		if @event
			prepare_task_form(subtitle: I18n.t("task.add"), retlnk: edit_event_path(@event), search_in: add_task_event_path(@event))
		else
			redirect_to events_path, data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit_task
	def edit_task
		if check_access(roles: [:manager, :coach], obj: @event)
			prepare_task_form(subtitle: I18n.t("task.edit"), retlnk: edit_event_path(@event), search_in: edit_task_event_path(@event), task_id: true)
		else
			redirect_to events_path, data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/load_chart
	def load_chart
		if check_access(roles: [:manager, :coach])
			header = helpers.event_title_fields(cols: @event.train? ? 3 : nil, chart: true)
			@chart = ModalPieComponent.new(header:, chart: helpers.event_workload(name: params[:name]))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/attendance
	def attendance
		if check_access(roles: [:manager, :coach], obj: @event)
			@title  = create_fields(helpers.event_attendance_title)
			@fields = create_fields(helpers.event_attendance_form_fields)
			@submit = create_submit
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/player_stats?player_id=X
	def player_stats
		if check_access(roles: [:manager, :coach], obj: @event.team)
			unless @event.rest?	# not keeing stats for holidays ;)
				@player = Player.find_by_id(params[:player_id] ? params[:player_id] : u_playerid)
				if @player&.id.to_i > 0	# we do have a player
					@title  = create_fields(helpers.event_title_fields(cols: @event.train? ? 3 : nil))
					@fields = create_fields(helpers.event_player_stats_fields)
					editor  = (u_manager? || @event.team.has_coach(u_coachid) || @event.team.has_player(u_playerid))
					@submit = create_submit(submit: @player ? edit_player_stats_event_path(@event, player_id: u_playerid) : nil, frame: "modal")
				else
					redirect_to @event.team, data: {turbo_action: "replace"}
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit_player_stats?player_id=X
	def edit_player_stats
		if check_access(roles: [:manager, :coach], obj: @event.team)
			unless @event.rest?	# not keeing stats for holidays ;)
				@player = Player.find_by_id(params[:player_id] ? params[:player_id] : u_playerid)
				if @player&.id.to_i > 0	# we do have a player
					@title  = create_fields(helpers.event_title_fields(cols: @event.train? ? 3 : nil))
					@fields = create_fields(helpers.event_edit_player_stats_fields)
					@submit = create_submit
				else
					redirect_to @event.team, data: {turbo_action: "replace"}
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# establish redirection & notice for based on udpate kind
		def prepare_update_redirect(e_data)
			if e_data[:task].present?
				@notice  = helpers.flash_message("#{I18n.t("task.updated")} ", "success")
				@retview = :edit
				@retlnk  = e_data[:task][:retlnk]
			elsif params[:event][:stats_attributes].present?	# just updated event stats
				@notice  = helpers.flash_message("#{I18n.t("stat.updated")} ", "success")
				@retview = :show
				if params[:retlnk]
					@retlnk  = params[:retlnk]
				else
					@retlnk  = current_user.player? ? team_path(@event.team, start_date: @event.start_date) : event_path(@event, retlnk: team_path(@event.team))
				end
			else
				@notice = helpers.event_update_notice(attendance: e_data[:player_ids])
				if e_data[:season_id].to_i > 0 # season event
					@retview = :index
					@retlnk  = season_events_path(e_data[:season_id], start_date: @event.start_date)
				elsif @event.rest?	# careful, these are modal
					@retview = :index
					@retlnk  = params[:retlnk] ? params[:retlnk] : team_events_path(@event, start_date: @event.start_date)
				else	# match or training session
					@retview = :show
					@retlnk  = event_path(@event)
				end
			end
			# returns whether we have something to save
			return (e_data[:task].present? || e_data[:player_ids].present? || e_data[:stats_attributes].present? || params[:outings].present?)
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

		# check stats - a single player updating an event
		def check_stats(stats, outings)
			@sport.parse_stats(@event, stats.values.first) if stats	# lets_ check them
			@sport.parse_stats(@event, outings) if outings	# lets_ check them
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

		# prepare new/edit event form
		def prepare_event_form(new: nil)
			if params[:season_id]
				@season = Season.find(event_params[:season_id])
			else
				@season = (@event.team and @event.team_id > 0) ? @event.team.season : Season.last
			end
			@title = create_fields(helpers.event_title_fields(form: true, cols: @event.match? ? 2 : nil))
			if @event.match?
				@fields  = create_fields(helpers.match_form_fields(new:))
				@grid    = create_grid(helpers.match_roster_grid(edit: true)) unless new
			end
			unless new # editing
				if @event.rest?
					c_ret = @event.team_id==0 ? seasons_path(season_id: @season.id) : team_path(@event.team)
				elsif @event.train?
					@btn_add = create_button({kind: "add", label: I18n.t("task.add"), url: add_task_event_path}) if (u_manager? || @event.team.has_coach(u_coachid))
					@drills  = @event.drill_list
				end
				c_ret = event_path(@event) unless c_ret
			end
			@submit = create_submit(close_return: c_ret)
		end

		# prepare edit/add task form
		def prepare_task_form(subtitle:, retlnk:, search_in:, task_id: nil)
			get_task(load_drills: true) # get the right @task/@drill
			@title       = create_fields(helpers.event_task_title(subtitle: subtitle))
			@search      = create_fields(helpers.drill_search_bar(search_in: search_in, task_id: task_id ? @task.id : nil, scratch: true))
			@fields      = create_fields(helpers.task_form_fields(search_in: search_in, retlnk: retlnk))
			@description = helpers.task_form_description
			@remarks     = create_fields(helpers.task_form_remarks)
			@submit      = create_submit(close_return: :back)
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
				@drills = filter!(Drill).pluck(:name, :id, :coach_id)
				@drill  = t_param[:drill_id] ? Drill.find(t_param[:drill_id]) : (@task.drill ? @task.drill : @drills.size>0 ? Drill.find(@drills.first[1]) : nil)
			end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_event
			@event = Event.find_by_id(params[:id])
			@sport = @event&.team&.sport&.specific
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
					:player_id,
					outings: {},
					player_ids: [],
					stats_attributes: {},
					event_targets_attributes: [:id, :priority, :event_id, :target_id, :_destroy, target_attributes: [:id, :focus, :aspect, :concept]],
					task: [:id, :task_id, :order, :drill_id, :duration, :remarks, :retlnk],
					tasks_attributes: [:id, :order, :drill_id, :duration, :remarks, :_destroy]
				)
		end
end
