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
# Managament of MudClub events (training sessions, matches, rest days)
class EventsController < ApplicationController
	include Filterable
	include PdfGenerator
	before_action :set_event, only: %i[ show edit add_task show_task edit_task athlete_stats edit_athlete_stats load_chart attendance copy update destroy ]
	before_action :set_athlete, only: %i[ athlete_stats edit_athlete_stats ]

	# GET /events or /events.json
	def index
		get_event_context

		@policy = check_policy!(EventPolicy, club: @club, team: @team)
		start_date = (params[:start_date] ? params[:start_date] : Date.today.at_beginning_of_month).to_date
		season     = @season || @team&.season
		url        = events_path(season:, start_date:)
		anchor     = { url: }
		@title     = create_fields(helpers.event_index_title(team: @team, season:))
		@calendar  = CalendarComponent.new(anchor:, obj: (@team || @club), start_date:, user: current_user, create_url: new_event_path)
		zerolnk    = (@team ? club_team_path(@team.club, @team) : club_path(@club, season_id: season&.id))
		@submit    = create_submit(close: :back, submit: nil, retlnk: back_link(default: zerolnk))
	end

	# GET /events/1 or /events/1.json
	def show
		@policy = check_policy!(EventPolicy, record: @event)

		respond_to do |format|
			title = helpers.event_header(cols: @event.kind_training? ? 3 : nil)
			format.pdf do
				if @policy.export?
					response.headers["Content-Disposition"] = "attachment; filename=drill.pdf"
					pdf = event_to_pdf(title)
					send_data pdf.render(filename: "#{@event}.pdf", type: "application/pdf")
				end
			end
			format.html do
				set_athlete
				@title = create_fields(title)
				submit = path_for(@event, action: :edit) if @policy.edit?
				person = @athlete&.person || u_person
				if @event.kind_holiday?
					@submit = create_submit(submit:, frame: :modal)
				elsif @event.kind_training? && @event.team.has_athlete?(person)	# we want to check athlete stats for a training session
					athlete_id = (
						@athlete ||
						@event.team.athletes(current: true).joins(:membership)
									.find_by(memberships: { person_id: person.id })
					)&.id
					redirect_to path_for(@event, action: athlete_stats, athlete_id:, cal: @cal), data: { turbo_action: "replace" }
				else	# gotta be a coach or manager
					if @event.kind_competition?
						@fields = create_fields(helpers.match_show)
						table   = helpers.match_roster_table
						@table  = create_table(table)
					else
						@targets = create_fields(helpers.training_target)
						@fields  = create_fields(helpers.training_show)
					end
					@submit = create_submit(close: :back, retlnk: back_link(default: anchor_lnk), submit:)
				end
			end
		end
	end

	# GET /events/new
	def new
		get_event_context
		@policy = check_policy!(EventPolicy, club: @club, team: @team)

		@event  = Event.prepare(team_id: @team&.id, club_id: @club&.id, kind: get_param(:kind))
		@season = @event.team&.season unless @event.team_id.to_i == 0
		@sport  = @event.team&.sport&.specific
		retlnk  = anchor_lnk
		if @event
			prepare_event_form(new: true)
		else
			redirect_to(retlnk, data: { turbo_action: "replace" })
		end
	end

	# GET /events/1/edit
	def edit
		@policy = check_policy!(EventPolicy, record: @event)

		prepare_event_form(new: false)
	end

	# POST /events or /events.json
	def create
		get_event_context
		@policy = check_policy!(EventPolicy, club: @club, team: @team)

		e_data = event_params
		@event = Event.prepare(event_params)
		respond_to do |format|
			@event.rebuild(e_data)
			if @event.save
				cru_return(e_data)
				link_holidays
				c_notice = helpers.event_create_notice
				modal    = @event.kind_holiday?
				register_action(:created, c_notice[:message], url: event_path(rdx: 2), modal:)
				format.html { redirect_to @retlnk, notice: c_notice, data: { turbo_action: "replace" } }
				format.json { render :show, status: :created, location: @retlnk }
			else
				prepare_event_form(new: true)
				format.html { render :new, status: :unprocessable_entity }
				format.json { render json: @event.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /events/1 or /events/1.json
	def update
		@policy = check_policy!(EventPolicy, record: @event)

		respond_to do |format|
			e_data   = event_params
			@athlete = Assignment.find_by_id(e_data[:athlete_id].presence)
			@event.rebuild(e_data)
			cru_return(e_data)
			if e_data[:athlete_assignment_ids].present?	# updated attendance
				changed = check_attendance(e_data[:athlete_assignment_ids])
			elsif e_data[:task].present? # updated task from edit_task_form
				changed = check_task(e_data[:task])
				@notice = @notice + @task.to_s if changed
			else	# it is an event update attempt
				seek_duplicate_event(e_data) if e_data[:copy].presence
				if @event.modified?	# do we need to save?
					if @event.save
						changed = true
						@retlnk = event_path
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
			format.html { redirect_to @retlnk, notice: @notice, data: { turbo_action: "replace" } }
			format.json { render @retview, status: :ok, location: @retlnk }
		end
	end

	# DELETE /events/1 or /events/1.json
	def destroy
		@policy = check_policy!(EventPolicy, record: @event)

		team       = @event.team
		start_date = @event.start_date
		@event.destroy
		respond_to do |format|
			next_url = team.id > 0 ? team : events_path(start_date:)
			next_act = team.id > 0 ? :show : :index
			a_desc   = helpers.event_delete_notice
			register_action(:deleted, a_desc[:message])
			format.html { redirect_to next_url, action: next_act.to_sym, status: :see_other, notice: a_desc, data: { turbo_action: "replace" } }
			format.json { head :no_content }
		end
	end

	# GET /events/1/attendance
	def attendance
		@policy = check_policy!(EventPolicy, record: @event)

		@header = create_fields(helpers.event_attendance_header)
		@fields = create_fields(helpers.event_attendance_form)
		@submit = create_submit(retlnk: event_path)
	end

	# GET /events/1/copy
	def copy
		@policy = check_policy!(EventPolicy, record: @event)

		@season = Season.latest
		@teams  = get_teams
		if @teams	# we have some teams we can copy to
			@fields = create_fields(helpers.event_copy)
			@submit = create_submit
		else
			notice  = helpers.flash_message("#{I18n.t("team.none")} ", "info")
			redirect_to event_path, notice:, data: { turbo_action: "replace" }
		end
	end

	# GET /events/1/add_task
	def add_task
		@policy = check_policy!(EventPolicy, record: @event)
		prepare_task_form("add", retlnk: edit_event_path, search_in: event_action_path(:add_task))
	end

	# GET /events/1/edit_task
	def edit_task
		@policy = check_policy!(EventPolicy, record: @event)
		prepare_task_form("edit", retlnk: edit_event_path, search_in: event_action_path(:add_task, task_id: @task.id), task_id: true)
	end

	# GET /events/1/show_task
	def show_task
		@policy = check_policy!(EventPolicy, record: @event)

		@task   = Task.find(params[:task_id])
		@fields = create_fields(helpers.task_show(task: @task, team: @event.team))
		submit  = edit_task_event_path(task_id: @task.id) if @policy.edit_task?
		@submit = create_submit(close: :back, retlnk: :back, submit:)
	end

	# GET /events/1/load_chart
	def load_chart
		@policy = check_policy!(EventPolicy, record: @event)

		header = helpers.event_header(cols: @event.kind_training? ? 3 : nil, chart: true)
		@chart = ModalPieComponent.new(header:, chart: helpers.event_workload(name: params[:name]))
	end

	# GET /events/1/athlete_stats?athlete_id=X
	def athlete_stats
		@policy  = check_policy!(EventPolicy, record: @event, person: @athlete&.person)

		if @assignment && @event.has_athlete?(@athlete&.person)	# we do have an athlete
			@header = create_fields(helpers.event_header(cols: @event.kind_training? ? 3 : nil))
			@fields = create_fields(helpers.event_athlete_stats)
			@submit = create_submit(submit: path_for(@event, action: :edit_athlete_stats, athlete_id: @athlete.id), frame: :modal)
		else
			redirect_to path_for(@team), data: { turbo_action: "replace" }
		end
	end

	# GET /events/1/edit_athlete_stats?athlete_id=X
	def edit_athlete_stats
		@policy  = check_policy!(EventPolicy, record: @event, person: @athlete&.person)

		if @event.has_athlete?(@athlete&.person)	# we do have an athlete
			@header = create_fields(helpers.event_header(cols: @event.kind_training? ? 3 : nil))
			@fields = create_fields(helpers.event_edit_athlete_stats)
			@submit = create_submit
		else
			redirect_to path_for(@team), data: { turbo_action: "replace" }
		end
	end

	private
		# context driven routing methods
		def events_path(start_date:, season: nil)
			@team ?
				club_team_events_path(@club, @team, start_date:) :
				club_events_path(@club, season_id: season&.id, start_date:)
		end

		def event_path(rdx: @rdx)	= path_for(@event, cal: @cal, rdx:)

		def event_action_path(action, **opts)
			path_for(@event, action:, cal: @cal, **opts)
		end

		def edit_event_path = event_action_path(:edit, season_id: @season&.id)

		def new_event_path(kind = nil)
			return nil unless @policy.new?
			if @team
				new_path_for(@team, :event, kind:, cal: @cal)
			else
				new_path_for(@club, :event, kind:, season_id: @season&.id, cal: @cal)
			end
		end

		# Update attendance for an event based on the submitted assignment IDs.
		#
		# Input: athlete_assignment_ids — Assignment UUIDs from the attendance form,
		#        which lists `@team.athletes.active.by_number` (athlete assignments).
		#
		# Validation on each submitted ID:
		#   1. Belongs to this team       (prevents cross-team injection)
		#   2. Is an athlete membership   (prevents non-athlete rows)
		#   3. Active on the event date   (prevents retroactive marking)
		# IDs failing validation are ignored — their attendance is left untouched
		# if it exists, not created.
		#
		# Returns true if any Attendance row changed state.
		def check_attendance(athlete_assignment_ids)
			team = @event.team
			return false unless team

			valid_ids = Assignment
				.of_membership_kind(:athlete)
				.where(team: team)
				.where(id: Array(athlete_assignment_ids).compact)
				.where("starts_on <= ?", @event.start_date)
				.where("ends_on IS NULL OR ends_on >= ?", @event.start_date)
				.pluck(:id)
				.to_set

			changed = false

			valid_ids.each do |aid|
				att = @event.attendances.find_or_initialize_by(assignment_id: aid)
				next if att.present?	# skip if already checked as present
				att.update!(status: :present)
				changed = true
			end

			# Existing attendances not in the incoming set become absent.
			# Note: we do NOT create absent rows for athletes not in the submission —
			# that would inflate the attendance graph with phantom "absent" records
			# for anyone the coach never looked at.
			@event.attendances.each do |att|
				next if valid_ids.include?(att.assignment_id)
				next if att.absent?
				att.update!(status: :absent)
				changed = true
			end

			changed
		end

		# Find the active athlete assignment for a person on a specific team on a given date.
		def find_active_athlete(person_id, team, date)
			Assignment.joins(:membership)
								.where(memberships: { person_id: person_id, club_id: team.club_id, kind: :athlete })
								.where(team: team)
								.where("starts_on <= ?", date)
								.where("ends_on IS NULL OR ends_on >= ?", date)
								.first
		end

		# check stats - a single athlete updating an event
		def check_stats(stats)
		  return false unless stats.respond_to?(:each_pair)

			stats_hash = stats.respond_to?(:to_unsafe_h) ? stats.to_unsafe_h : stats.to_h
			@sport.parse_stats(@event, stats_hash)
			@sport.update_stats(event_id: @event.id, stats_data: stats_hash)
			true
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

		# establish redirection & notice for based on update kind
		def cru_return(e_data)
			if e_data[:task].present?
				@notice  = I18n.t("training.task.messages.updated")
				@retview = :edit
				@retlnk  = edit_event_path
			elsif params[:event].present?
				@retview = :show
				if @event.kind_holiday? #--> Calendar view
					@retlnk = events_path(start_date: @event.start_date)
				else
					@retlnk = event_path unless @event.kind_holiday?
				end

				if @event.modified?
					@notice = I18n.t("#{@event.kind}.updated")
				elsif	e_data[:athlete_assignment_ids].present?	# assignments to participate
					@notice = I18n.t("#{@event.kind}.att_check")
				elsif params[:event][:stats_attributes].present? || params[:outings].present?	# updated stats/outings
					@notice = I18n.t("training.stat.messages.updated")
				else
					@notice = I18n.t("status.no_data")
				end
			end
		end

		# pdf export of @event content
		def event_to_pdf(header)
			p_header = header.take(2)
			p_header[0][1][:cols] = 1
			p_header[1][0][:cols] = 1
			footer = "#{@event.team} #{@event.date_string}"
			pdf    = pdf_create(header: p_header, footer:)# , full_width: true)
			if @event.kind == "train"
				pdf_label_text(label: I18n.t("training.target.label.many"), text: @event.print_targets)
				pdf_separator_line(style: "empty")
				@event.tasks.each do |task|
					pdf_subtitle(task.headstring)
					pdf_rich_text(task.drill.explanation) if task.drill.explanation&.present?
					pdf_rich_text(task.remarks) if task.remarks&.present?
					pdf_separator_line(style: "empty")
				end
				pdf_new_page
				pdf_subtitle(I18n.t("calendar.attendance.label.single"))
				@event.team.athletes.by_number.each do |athlete|
					pdf_label_text(label: athlete.to_s(style: 3), text: "_")
				end
				pdf_separator_line(style: "empty")
				pdf_subtitle(I18n.t("training.task.remarks.label"))
			end
			pdf
		end

		# try to establish where we've been called from...
		def get_event_context
			@cal = get_param(:cal)
			if @event&.team
				@team = @event.team
				@club = @event.team.club
			else
				t_id  = get_param(:team_id)
				@team = Team.find(t_id) if t_id
				@club = @team ? @team.club : @event&.club || @club
			end
		end

		# return array of valid team options for a selector
		def get_teams
			teams = u_manager? ?
				u_club&.teams&.for_season(@season) || [] :
				current_user.team_list(season_id: @season.id)
			opts  = []
			teams.each do |team|
				opts << { id: team.id, name: team.name }
			end
			opts
		end

		# determine the right retlnk for a show/new operation
		def anchor_lnk
			if @cal && @event	# return to a calendar view
				events_path(season: @event.team.season, start_date: @event.start_date)
			elsif @team
				path_for(@team)
			else	# return to regular parent view
				parent_path_for(@event, season_id: @season&.id) || "/"
			end
		end

		# determine task/drill objects from params received
		def get_task(load_drills: nil)
			if params[:event]
				t_param = event_params[:task]
			elsif params[:task] # comes from a dynamic refresh
				tmp     = params[:task][:drill_id]&.split("|")
				t_param = { drill_id: tmp[0], task_id: tmp[1] }
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
			# Avoid events that are not general club holidays
			return unless  @event&.kind_holiday? && @event.team_id.to_i == 0

			# copy holiday to all teams in the same season (if it exists)
			season = Season.search_date(@event.start_date)
			if season # we have a season for this event
				@club.teams.for_season(season).each do |team|
					e_copy = @event.dup
					e_copy.team_id = team.id
					e_copy.save
					team.events << e_copy
				end
			end
		end

		# prepare new/edit event form
		def prepare_event_form(new: nil)
			@header = create_fields(helpers.event_header(form: true, cols: @event.kind_competition? ? 2 : nil))
			if @event.kind_competition?
				@fields  = create_fields(helpers.match_form(new:))
				unless new
					table  = helpers.match_roster_table(edit: true)
					@table = create_table(table)
				end
			end
			unless new # editing
				unless @event.kind_holiday?
					r_lnk = event_path
					if @event.kind_training?
						@btn_add = create_button({ kind: :add, label: Task.act(:add), url: event_action_path(:add_task) }) if @policy.create?
						@drills  = @event.drill_list
					end
					@submit = create_submit(close: :back, retlnk: r_lnk)
				end
			end
			@submit ||= create_submit(retlnk: @retlnk)
		end

		# prepare edit/add task form
		def prepare_task_form(action, retlnk:, search_in:, task_id: nil)
			get_task(load_drills: true) # get the right @task/@drill
			scratch      = task_id.nil?
			title        = helpers.event_task_header(subtitle: I18n.t("task.#{action}"))
			title        << helpers.drill_search_bar(search_in:, task_id: @task.id, scratch:, cols: 4)
			@header      = create_fields(title)
			@fields      = create_fields(helpers.task_form(search_in:))
			@description = helpers.task_form_description
			@remarks     = create_fields(helpers.task_form_remarks)
			@submit      = create_submit(retlnk: :back)
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
				@event.targets.each { |target| e_copy.targets << target.dup }	# copy targets
				e_copy.tasks.delete_all
				@event.tasks.each { |task| e_copy.tasks << task.dup }	# copy tasks
				@event          = e_copy
			end
		end

		# before ahtlete_stats actions
		def set_athlete
			@athlete = Assignment.find_by(id: get_param(:athlete_id))
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_event
			eventid   = get_param(:id) || get_param(:event_id)
			@event    = Event.find_by_id(eventid)
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
					:home,
					:homecourt_id,
					:hour,
					:kind_id,
					:location_id,
					:min,
					:p_for,
					:p_opp,
					:athlete_id,
					:rdx,
					:start_date,
					:start_time,
					:skill_id,
					:task_id,
					:team_id,
					:season_id,
					outings: {},
					event_targets_attributes: [ :id, :priority, :event_id, :target_id, :_destroy, target_attributes: [ :id, :focus, :aspect, :concept ] ],
					athlete_assignment_ids: [],
					stats_attributes: [],
					task: [ :id, :task_id, :order, :drill_id, :duration, :remarks, :retlnk ],
					tasks_attributes: [ :id, :order, :drill_id, :duration, :remarks, :_destroy ]
				)
		end
end
