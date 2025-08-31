# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
# Managament of MudClub teams - belonging to a club
class TeamsController < ApplicationController
	include Filterable
	before_action :set_team_context, only: [ :index, :show, :roster, :slots, :edit, :edit_roster, :attendance, :targets, :edit_targets, :plan, :edit_plan, :new, :update, :destroy ]

	# GET /club/x/teams
	# GET /club/x/teams.json
	def index
		if check_access(roles: [ :admin, :manager, :coach, :secretary ])
			@club  = Club.find_by_id(@clubid)
			@teams = filter!(Team).real.order(:category_id, :name).where(club_id: @clubid)
			respond_to do |format|
				format.xlsx do
					f_name = "#{@season.name(safe: true)}-players.xlsx"
					a_desc = "#{I18n.t("player.export")} '#{f_name}'"
					register_action(:exported, a_desc, url: teams_path(rdx: 2))
					response.headers["Content-Disposition"] = "attachment; filename=#{f_name}"
				end
				format.html do
					title   = helpers.team_title_fields(title: I18n.t("team.many"), search: true)
					page    = paginate(@teams)	# paginate results
					grid    = helpers.team_grid(teams: page, add_teams: club_manager?(@club))
					zerolnk = @clubid ? club_path(@clubid, rdx: @rdx) : (u_admin? ? clubs_path(rdx: @rdx) : "/")
					retlnk  = base_lnk(zerolnk)
					submit  = { kind: :export, url: club_teams_path(@clubid, format: :xlsx, season_id: @seasonid), working: false } if user_in_club? && (u_manager? || u_secretary?)
					create_index(title:, grid:, page:, retlnk:, submit:)
					render :index
				end
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1
	# GET /teams/1.json
	def show
		if @team && user_in_club? && check_access(roles: [ :coach, :manager, :secretary ])
			@sport   = @team.sport.specific
			title    = helpers.team_title_fields(title: @team.nick)
			w_l = @team.win_loss
			if w_l[:won] > 0 || w_l[:lost] > 0
				wlstr = "(#{w_l[:won]}#{I18n.t("match.won")} - #{w_l[:lost]}#{I18n.t("match.lost")})"
				title << [ helpers.gap_field, { kind: :text, value: wlstr } ]
			end
			@title   = create_fields(title)
			@coaches = create_fields(helpers.team_coaches)
			if u_manager? || u_coach?
				@links = create_fields(helpers.team_links)
				@grid  = create_fields(helpers.event_list_grid(obj: @team))
				submit = edit_team_path(@team, rdx: @rdx) if team_manager?
			else
				start_date = (params[:start_date] ? params[:start_date] : Date.today.at_beginning_of_month).to_date
				anchor     = { url: team_events_path(@team), rdx: @rdx }
				@calendar  = CalendarComponent.new(anchor:, start_date:, obj: @team, user: current_user)
				submit     = nil
			end
			zerolnk = club_teams_path(club_id: @clubid, season_id: @seasonid, rdx: @rdx)
			@submit = create_submit(close: :back, retlnk: base_lnk(zerolnk), submit:, frame: (submit ? "modal" : nil))
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/new - can only be called from a teams index
	def new
		if u_manager?
			@eligible_coaches = @club.coaches
			@team   = Team.new(club_id: @club.id, sport_id: Sport.first.id, nick: @club.nick, season_id: (params[:season_id].presence&.to_i || Season.latest.id))
			@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.new")))
			@submit = create_submit(retlnk: club_teams_path(@clubid, rdx: 0))
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1/edit
	def edit
		if @team && team_manager?
			@eligible_coaches = @club.coaches
			@sport  = @team.sport.specific
			@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.edit")))
			@submit = create_submit
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# POST /teams
	# POST /teams.json
	def create
		@club = Club.find(@clubid)
		if club_manager?(@club)
			respond_to do |format|
				if team_params
					@team = Team.build(team_params)
					if @team.save
						a_desc = "#{I18n.t("team.created")} '#{@team}'"
						c_path = (user_in_club? ? cru_return : club_teams_path(@clubid, rdx: @rdx))
						register_action(:created, a_desc, url: team_path(@team, rdx: 2))
						format.html { redirect_to c_path, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
						format.json { render :index, status: :created, location: c_path }
					else
						@eligible_coaches = Coach.active
						@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.new")))
						@submit = create_submit
						format.html { render :new }
						format.json { render json: @team.errors, status: :unprocessable_entity }
					end
				else	# no data to save...
					format.html { redirect_to retlnk, notice: n_notice, data: { turbo_action: "replace" } }
					format.json { redirect_to retlnk, status: :ok, location: retlnk }
				end
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# PATCH/PUT /teams/1
	# PATCH/PUT /teams/1.json
	def update
		if @team && team_manager?
			respond_to do |format|
				n_notice = no_data_notice(trail: @team.to_s)
				retlnk   = cru_return
				if team_params
					@team.rebuild(team_params)
					if @team.modified?
						if @team.save
							a_desc = "#{I18n.t("team.updated")} '#{@team}'"
							register_action(:updated, a_desc, url: team_path(rdx: 2))
							format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
							format.json { redirect_to retlnk, status: :created, location: retlnk }
						else
							@eligible_coaches = Coach.active
							@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.edit")))
							@submit = create_submit
							format.html { render :edit, data: { "turbo-frame": "replace" }, notice: helpers.flash_message(@team.errors, "error") }
							format.json { render json: @team.errors, status: :unprocessable_entity }
						end
					else	# no data to save...
						format.html { redirect_to retlnk, notice: n_notice, data: { turbo_action: "replace" } }
						format.json { render json: @team.errors, status: :unprocessable_entity }
					end
				else	# no data to save...
					format.html { redirect_to retlnk, notice: n_notice, data: { turbo_action: "replace" } }
					format.json { redirect_to retlnk, status: :ok, location: retlnk }
				end
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# DELETE /teams/1
	# DELETE /teams/1.json
	def destroy
		# cannot destroy placeholder teams (id: 0 || -1)
		if @team && @team&.id&.to_i > 0 && club_manager?
			t_name = @team.to_s
			@team.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("team.deleted")} '#{t_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to club_teams_path(@clubid, rdx: @rdx), status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1/roster
	def roster
		if @team && check_access(roles: [ :manager, :coach, :secretary ], obj: @club, both: true)
			title   = helpers.team_title_fields(title: @team.nick)
			players = @team.players
			title << icon_subtitle("player", I18n.t("team.roster"), namespace: @team.sport.name)
			title.last << { kind: :string, value: "(#{players.count} #{I18n.t("player.abbr")})" }
			@title  = create_fields(title)
			@title  = create_fields(title)
			@grid   = create_grid(helpers.player_grid(team: @team, players: players.order(:number)))
			submit  = edit_roster_team_path(rdx: @rdx) if team_manager?
			@submit = create_submit(close: :back, retlnk: team_path(rdx: @rdx), submit:)
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1/edit_roster
	def edit_roster
		if @team && team_manager?
			title = helpers.team_title_fields(title: @team.to_s)
			title << icon_subtitle("player", I18n.t("team.roster_edit"), namespace: @team.sport.name)
			@title  = create_fields(title)
			@submit = create_submit(close: :cancel, retlnk: roster_team_path(rdx: @rdx))
			@eligible_players = @team.eligible_players
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1/slots
	def slots
		if @team && user_in_club?
			title   = helpers.team_title_fields(title: @team.to_s)
			@title  = create_fields(title)
			@fields = create_fields(helpers.team_slots_fields) unless @team.slots.empty?
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1/targets
	def targets
		if @team && check_access(roles: [ :coach, :manager ], obj: @club, both: true)
			global_targets(true)	# get & breakdown global targets
			title = helpers.team_title_fields(title: @team.to_s)
			title << icon_subtitle("target", I18n.t("target.many"))
			@title  = create_fields(title)
			edit    = edit_targets_team_path(rdx: @rdx) if team_manager?
			@fields = create_fields(helpers.team_targets_show_fields)
			@submit = create_submit(close: :back, retlnk: team_path(rdx: @rdx), submit: edit)
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1/edit_targets
	def edit_targets
		if @team && team_manager?
			redirect_to("/", data: { turbo_action: "replace" }) unless @team
			global_targets(true)	# get global targets
			title   = helpers.team_title_fields(title: @team.to_s)
			title << icon_subtitle("target", I18n.t("target.edit"))
			@title  = create_fields(title)
			@submit = create_submit(close: :cancel, retlnk: targets_team_path(rdx: @rdx))
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1/edit_targets
	def plan
		if @team && check_access(roles: [ :coach, :manager ], obj: @club, both: true)
			plan_targets
			title = helpers.team_title_fields(title: @team.to_s)
			title << icon_subtitle("plan", I18n.t("plan.single"))
			@title = create_fields(title)
			edit    = edit_plan_team_path(rdx: @rdx) if team_manager?
			@fields = create_fields(helpers.team_plan_accordion)
			@submit = create_submit(close: :back, retlnk: team_path(rdx: @rdx), submit: edit)
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1/edit_plan
	def edit_plan
		if @team && team_manager?
			redirect_to("/", data: { turbo_action: "replace" }) unless @team
			plan_targets
			title   = helpers.team_title_fields(title: @team.to_s)
			title << icon_subtitle("plan", I18n.t("plan.edit"))
			@title  = create_fields(title)
			@submit = create_submit(close: :cancel, retlnk: plan_team_path(rdx: @rdx))
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /teams/1/attendance
	def attendance
		if @team && check_access(roles: [ :coach, :manager, :secretary ], obj: @club, both: true)
			title  = helpers.team_title_fields(title: @team.to_s)
			title << icon_subtitle("attendance", I18n.t("calendar.attendance"))
			@title = create_fields(title)
			a_data = helpers.team_attendance_grid
			if a_data
				@grid = create_grid({ title: a_data[:title], rows: a_data[:rows] })
				@att_data = [ a_data[:chart] ] if a_data
			end
			@submit = create_submit(submit: nil)
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	private
		# wrapper to set return link for create && update operations
		def cru_return
			if param_passed(:team, :player_ids)	# roster view
				roster_team_path(@team, rdx: @rdx)
			elsif param_passed(:team, :team_targets_attributes)	# targets or plan
				first_target = team_params[:team_targets_attributes].to_h.first
				if first_target
					if first_target[1]["month"] == "0"	# global team targets
						targets_team_path(@team, rdx: @rdx)
					else	# team monthly targets
						plan_team_path(@team, rdx: @rdx)
					end
				else	# base team view
					team_path(@team, rdx: @rdx)
				end
			else	# team view also
				team_path(@team, rdx: @rdx)
			end
		end

		# get team targets for a specific month
		def fetch_targets(month)
			case month
			when Integer
				tgt = @team.team_targets.monthly(month)
				m   = { i: month, name: I18n.t("calendar.monthnames_a")[month] }
			when Array
				tgt = @team.team_targets.monthly(month[1])
				m   = { i: month[1], name: I18n.t("calendar.monthnames_a")[month[1]] }
			else
				tgt = @team.team_targets.monthly(month[:i])
				m   = { i: month[:i], name: month[:name] }
			end
			t_d_ind = filter(tgt, 1, 2)
			t_o_ind = filter(tgt, 1, 1)
			t_d_col = filter(tgt, 2, 2)
			t_o_col = filter(tgt, 2, 1)
			{ i: m[:i], month: m[:name], t_d_ind: t_d_ind, t_o_ind: t_o_ind, t_d_col: t_d_col, t_o_col: t_o_col }
		end

		# filters a set of TeamTargets by aspect & focus of the associated targets
		def filter(tgts, aspect, focus)
			res = Array.new
			tgts.each { |tgt|
				res << tgt if (tgt.target.aspect_before_type_cast == aspect) and (tgt.target.focus_before_type_cast == focus)
			}
			res
		end

		# retrieve targets for the team
		def global_targets(breakdown = false)
			targets = @team.team_targets.global
			if breakdown
				@t_d_gen = { i: 0, aspect: 0, focus: 2, tgts: filter(targets, 0, 2) }
				@t_d_ind = { i: 0, aspect: 1, focus: 2, tgts: filter(targets, 1, 2) }
				@t_d_col = { i: 0, aspect: 2, focus: 2, tgts: filter(targets, 2, 2) }
				@t_o_gen = { i: 0, aspect: 0, focus: 1, tgts: filter(targets, 0, 1) }
				@t_o_ind = { i: 0, aspect: 1, focus: 1, tgts: filter(targets, 1, 1) }
				@t_o_col = { i: 0, aspect: 2, focus: 1, tgts: filter(targets, 2, 1) }
			else
				@targets = targets
			end
		end

		# reused across differnet views
		def icon_subtitle(icon, label, namespace: "common")
			[
				helpers.symbol_field(icon, { namespace: }, size: "30x30", align: "right", css: "mr-1"),
				{ kind: :side_cell, value: label, align: "left" }
			]
		end

		# retrieve monthly targets for the team
		def plan_targets
			@months = @team.season.months(true)
			@targets = Array.new
			@months.each { |m| @targets << fetch_targets(m)	}
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_team_context
			if (t_id = (params[:id].presence || p_teamid))
				@team   = Team.find_by_id(t_id)
				@teamid = @team&.id
				@clubid = @team&.club&.id
			end
			@club     = Club.find(@clubid)
			s_id      = @team&.season&.id || session.dig("team_filters", "season_id") || p_seasonid
			@season   = Season.search(s_id) unless s_id == @season&.id
			@seasonid = @season&.id
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def team_params
			params.require(:team).permit(
				:id,
				:category_id,
				:club_id,
				:coaches,
				:division_id,
				:homecourt_id,
				:name,
				:nick,
				:players,
				:rdx,
				:rules,
				:season_id,
				:sport_id,
				:targets,
				:team_targets,
				coaches_attributes: [ :id ],
				coach_ids: [],
				player_ids: [],
				players_attributes: [ :id ],
				targets_attributes: [],
				team_targets_attributes: {}
			)
		end
end
