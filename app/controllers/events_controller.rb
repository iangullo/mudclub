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
	before_action :set_event, only: %i[ show edit add_task show_task edit_task task_drill load_chart attendance update destroy ]

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
		if check_access(roles: [:admin, :coach], obj: @event)
			retlnk = params[:retlnk]
			@title  = create_fields(helpers.event_title_fields(cols: @event.train? ? 3 : nil))
			if @event.rest?
				@submit = create_submit(submit: (u_admin? or @event.team.has_coach(u_coachid)) ? edit_event_path(season_id: params[:season_id]) : nil, frame: "modal")
			else
				@submit = create_submit(close: "back", close_return: retlnk ? retlnk : team_path(@event.team), submit: (u_admin? or @event.team.has_coach(u_coachid)) ? edit_event_path(season_id: params[:season_id]) : nil)
				@fields = create_fields(@event.match? ? helpers.match_show_fields : helpers.training_show_fields)
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/new
	def new
		if check_access(roles: [:admin, :coach])
			@event  = Event.prepare(event_params)
			if @event
				if @event.rest? or (@event.team_id >0 and @event.team.has_coach(u_coachid))
					prepare_event_form(new: true)
					@submit = create_submit
				else
					redirect_to(u_admin? ? "/slots" : @event.team)
				end
			else
				redirect_to(u_admin? ? "/slots" : "/", data: {turbo_action: "replace"})
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit
	def edit
		if check_access(roles: [:admin, :coach], obj: @event)
			prepare_event_form(new: false)
			if @event.rest?
				c_ret =  @event.team_id==0 ? seasons_path(season_id: @season.id) : team_path(@event.team)
			else
				c_ret =  event_path(@event)
			end
			@submit = create_submit(close_return: c_ret)
			@drills = @event.drill_list if @event.train?
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /events or /events.json
	def create
		@event = Event.prepare(event_params)
		if check_access(roles: [:admin, :coach], obj: @event)
			respond_to do |format|
				@event.rebuild(event_params)
				if @event.save
					link_holidays
					c_notice = helpers.event_create_notice
					register_action(:created, c_notice[:message])
					format.html { redirect_to @event.team_id > 0 ? team_path(@event.team) : events_url, notice: c_notice, data: {turbo_action: "replace"} }
					format.json { render :show, status: :created, location: events_path}
				else
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
		if check_access(roles: [:admin, :coach], obj: @event)
			respond_to do |format|
				e_data   = event_params
				u_notice = e_data[:task] ? helpers.flash_message("#{I18n.t("task.updated")} '#{@task.to_s}'", "success") : helpers.event_update_notice
				register_action(:updated, u_notice[:message])
				@event.rebuild(e_data)
				if e_data[:player_ids]  # we are updating attendance
					check_attendance(e_data[:player_ids])
					format.html { redirect_to @event, notice: u_notice, data: {turbo_action: "replace"}}
					format.json { render :show, status: :ok, location: @event }
				elsif e_data[:task]
					check_task(e_data[:task]) # updated task from edit_task_form (add or edit)
					format.html { redirect_to e_data[:task][:retlnk], notice: u_notice }
					format.json { render :edit, status: :ok, location: @event }
				elsif @event.save
					if e_data[:season_id].to_i > 0 # season event
						format.html { redirect_to season_path(e_data[:season_id]), notice: u_notice, data: {turbo_action: "replace"} }
						format.json { render :show, status: :ok, location: @event }
					elsif e_data[:tasks_attributes] # a training session
						@event.tasks.reload
						format.html { redirect_to @event, notice: u_notice }
						format.json { render :show, status: :ok, location: @event }
					else # updating match
						format.html { redirect_to @event, notice: u_notice, data: {turbo_action: "replace"} }
					end
				else
					format.html { render :edit, status: :unprocessable_entity }
					format.json { render json: @event.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to events_path, data: {turbo_action: "replace"}
		end
	end

	# DELETE /events/1 or /events/1.json
	def destroy
		if check_access(roles: [:admin, :coach], obj: @event)
			erase_links
			team   = @event.team
			@event.destroy
			respond_to do |format|
				next_url = team.id > 0 ? team_path : events_url
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
		if check_access(roles: [:admin, :coach], obj: @event)
			@task   = Task.find(params[:task_id])
			@fields = create_fields(helpers.task_show_fields(task: @task, team: @event.team))
			@submit = create_submit(close: "back", close_return: :back, submit: (u_admin? or @event.team.has_coach(u_coachid)) ? edit_task_event_path(task_id: @task.id) : nil)
		else
			redirect_to events_path, data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/add_task
	def add_task
		check_access(roles: [:admin], obj: @event)
		if @event
			prepare_task_form(subtitle: I18n.t("task.add"), retlnk: edit_event_path(@event), search_in: add_task_event_path(@event))
		else
			redirect_to events_path, data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/edit_task
	def edit_task
		if check_access(roles: [:admin, :coach], obj: @event)
			prepare_task_form(subtitle: I18n.t("task.edit"), retlnk: event_path(@event), search_in: edit_task_event_path(@event), task_id: true)
		else
			redirect_to events_path, data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/load_chart
	def load_chart
		if check_access(roles: [:admin, :coach], obj: @event)
			header = helpers.event_title_fields(cols: @event.train? ? 3 : nil, chart: true)
			@chart = ModalPieComponent.new(header:, chart: helpers.event_workload(name: params[:name]))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /events/1/attendance
	def attendance
		if check_access(roles: [:admin, :coach], obj: @event)
			@title  = create_fields(helpers.event_attendance_title)
			@fields = create_fields(helpers.event_attendance_form_fields)
			@submit = create_submit
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
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

		# prepare new/edit event form
		def prepare_event_form(new:)
			if params[:season_id]
				@season = Season.find(event_params[:season_id])
			else
				@season = (@event.team and @event.team_id > 0) ? @event.team.season : Season.last
			end
			@title  = create_fields(helpers.event_title_fields(form: true, cols: @event.match? ? 2 : nil))
			if @event.match?
				m_fields = new ? helpers.match_new_fields : helpers.match_form_fields
				@fields  = create_fields(m_fields)
			end
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
				@drills = filter!(Drill).pluck(:name, :id)
				@drill  = t_param[:drill_id] ? Drill.find(t_param[:drill_id]) : (@task.drill ? @task.drill : @drills.size>0 ? Drill.find(@drills.first[1]) : nil)
			end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_event
			@event  = Event.find_by_id(params[:id])
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
