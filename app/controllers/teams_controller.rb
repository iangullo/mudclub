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
class TeamsController < ApplicationController
	include Filterable
	#skip_before_action :verify_authenticity_token, :only => [:create, :edit, :new, :update, :check_reload]
	before_action :set_team, only: [:index, :show, :roster, :slots, :edit, :edit_roster, :attendance, :targets, :edit_targets, :plan, :edit_plan, :new, :update, :destroy]

	# GET /teams
	# GET /teams.json
	def index
		if check_access(roles: [:admin, :coach])
			@topbar.title = helpers.team_title_fields(title: I18n.t("team.many"), search: true)
			@grid   = create_grid(helpers.team_grid(teams: @teams, season: not(@season), add_teams: u_admin?))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /teams/new
	def new
		if check_access(roles: [:admin])
			@eligible_coaches = Coach.active
			@team   = Team.new(season_id: params[:season_id] ? params[:season_id] : Season.last.id)
			@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.new")))
			@submit = create_submit
		else
			redirect_to teams_path, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1
	# GET /teams/1.json
	def show
		if check_access(roles: [:admin, :coach])
			@topbar.title = helpers.team_title_fields(title: @team.to_s)
			@links = create_fields(helpers.team_links)
			@grid  = create_fields(helpers.event_list_grid(events: @team.events.short_term, obj: @team, retlnk: team_path(@team)))
		else
			redirect_to teams_path, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/roster
	def roster
		if check_access(roles: [:admin, :coach])
			title  = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "player.svg", size: "30x30"}, {kind: "label", value: I18n.t("team.roster")}]
			@topbar.title = title
			@grid   = create_grid(helpers.player_grid(players: @team.players.order(:number), obj: @team))
			@submit = create_submit(close: "back", close_return: team_path(@team), submit:(u_admin? or @team.has_coach(u_coachid)) ? edit_roster_team_path : nil, frame: "modal")
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/edit_roster
	def edit_roster
		if check_access(roles: [:admin, :coach], obj: @team)
			title = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "player.svg", size: "30x30"}, {kind: "label", value: I18n.t("team.roster_edit")}]
			@title  = create_fields(title)
			@submit = create_submit(close: "cancel", close_return: :back)
			@eligible_players = @team.eligible_players
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/slots
	def slots
		if check_access(roles: [:admin, :coach])
			title   = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "timetable.svg", size: "30x30"}, {kind: "label", value: I18n.t("slot.many")}]
			@fields = create_fields(title)
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/targets
	def targets
		if check_access(roles: [:admin, :coach])
			global_targets(true)	# get & breakdown global targets
			title = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "target.svg", size: "30x30"}, {kind: "label", value: I18n.t("target.many")}]
			@topbar.title = title
			@submit = create_submit(close: "back", close_return: team_path(@team), submit: @team.has_coach(u_coachid) ? edit_targets_team_path : nil)
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end

	end

	# GET /teams/1/edit_targets
	def edit_targets
		if check_access(roles: [:admin], obj: @team)
			redirect_to("/", data: {turbo_action: "replace"}) unless @team
			global_targets(false)	# get global targets
			title   = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "target.svg", size: "30x30"}, {kind: "label", value: I18n.t("target.edit")}]
			@topbar.title = title
			@submit = create_submit(close: "cancel", close_return: :back)
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/edit_targets
	def plan
		if check_access(roles: [:admin, :coach])
			plan_targets
			title = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "teamplan.svg", size: "30x30"}, {kind: "label", value: I18n.t("plan.single")}]
			@topbar.title = title
			@edit  = edit_plan_team_path if @team.has_coach(u_coachid)
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/edit_plan
	def edit_plan
		if check_access(roles: [:admin], obj: @team)
			redirect_to("/", data: {turbo_action: "replace"}) unless @team
			plan_targets
			title   = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "teamplan.svg", size: "30x30"}, {kind: "label", value: I18n.t("plan.edit")}]
			@topbar.title = title
			@submit = create_submit(close: "cancel", close_return: :back)
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/attendance
	def attendance
		if check_access(roles: [:admin, :coach])
			title  = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "attendance.svg", size: "30x30"}, {kind: "label", value: I18n.t("calendar.attendance")}]
			@title = create_fields(title)
			a_data = helpers.team_attendance_grid
			if a_data
				@grid = create_grid({title: a_data[:title], rows: a_data[:rows]})
				@att_data = [a_data[:chart]] if a_data
			end
			@submit = create_submit(submit:nil)
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/edit
	def edit
		if check_access(roles: [:admin], obj: @team)
			@eligible_coaches = Coach.active
			@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.edit")))
			@submit = create_submit
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end
	end

	# POST /teams
	# POST /teams.json
	def create
		if check_access(roles: [:admin])
			@team = Team.new(team_params)
			respond_to do |format|
				if @team.save
					a_desc = "#{I18n.t("team.created")} '#{@team.to_s}'"
					register_action(:created, a_desc)
					format.html { redirect_to teams_path, notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: teams_path }
				else
					@eligible_coaches = Coach.active
					@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.new")))
					@submit = create_submit
					format.html { render :new }
					format.json { render json: @team.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to teams_path, data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /teams/1
	# PATCH/PUT /teams/1.json
	def update
		if check_access(roles: [:admin], obj: @team)
			respond_to do |format|
				n_notice = no_data_notice(trail: @team.to_s)
				if params[:team]
					retlnk = params[:team][:retlnk]
					@team.rebuild(params[:team])
					if @team.modified?
						if @team.save
							a_desc = "#{I18n.t("team.updated")} '#{@team.to_s}'"
							register_action(:updated, a_desc)
							format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
							format.json { redirect_to retlnk, status: :created, location: retlnk }
						else
							@eligible_coaches = Coach.active
							@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.edit")))
							@submit = create_submit
							format.html { render :edit, data:{"turbo-frame": "replace"}, notice: helpers.flash_message(@team.errors,"error") }
							format.json { render json: @team.errors, status: :unprocessable_entity }
						end
					else	# no data to save...
						format.html { redirect_to retlnk, notice: n_notice, data: {turbo_action: "replace"} }
						format.json { render json: @team.errors, status: :unprocessable_entity }
					end
				else	# no data to save...
					format.html { redirect_to retlnk, notice: n_notice, data: {turbo_action: "replace"} }
					format.json { redirect_to retlnk, status: :ok, location: retlnk }
				end
			end
		else
			redirect_to @team, data: {turbo_action: "replace"}
		end
	end

	# DELETE /teams/1
	# DELETE /teams/1.json
	def destroy
		if check_access(roles: [:admin]) and @team
			t_name = @team.to_s
			@team.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("team.deleted")} '#{t_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to teams_path, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to teams_path, data: {turbo_action: "replace"}
		end
	end

	private
		# retrieve targets for the team
		def global_targets(breakdown=false)
			targets = @team.team_targets.global
			if breakdown
				@t_d_gen = filter(targets, 0, 2)
				@t_d_ind = filter(targets, 1, 2)
				@t_d_col = filter(targets, 2, 2)
				@t_o_gen = filter(targets, 0, 1)
				@t_o_ind = filter(targets, 1, 1)
				@t_o_col = filter(targets, 2, 1)
			end
		end

		# retrieve monthly targets for the team
		def plan_targets
			@months = @team.season.months(true)
			@targets = Array.new
			@months.each { |m| @targets << fetch_targets(m)	}
		end

		# get team targets for a specific month
		def fetch_targets(month)
			case month
			when Integer
				tgt = @team.team_targets.monthly(month)
				m   = {i: month, name: I18n.t("calendar.monthnames_a")[month]}
			when Array
				tgt = @team.team_targets.monthly(month[1])
				m   = {i: month[1], name: I18n.t("calendar.monthnames_a")[month[1]]}
			else
				tgt = @team.team_targets.monthly(month[:i])
				m   = {i: month[:i], name: month[:name]}
			end
			t_d_ind = filter(tgt, 1, 2)
			t_o_ind = filter(tgt, 1, 1)
			t_d_col = filter(tgt, 2, 2)
			t_o_col = filter(tgt, 2, 1)
			{i: m[:i], month: m[:name], t_d_ind: t_d_ind, t_o_ind: t_o_ind, t_d_col: t_d_col, t_o_col: t_o_col}
		end

		# filters a set of TeamTargets by aspect & focus of the associated targets
		def filter(tgts,aspect,focus)
			res = Array.new
			tgts.each { |tgt|
				res << tgt if (tgt.target.aspect_before_type_cast == aspect) and (tgt.target.focus_before_type_cast == focus)
			}
			return res
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_team
			if params[:id]=="coaching"
				@team = current_user.coach.teams.first
			else
				@team = Team.find_by_id(params[:id]) if params[:id]
			end
			if @team
				@season = @team.season
			else
				s_id    = params[:season_id].presence || session.dig('team_filters', 'season_id')
				@season = s_id ? Season.find_by(id: s_id) : Season.latest
			end
			@season = Season.last unless @season
			@teams  = Team.search(@season&.id)
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def team_params
			params.require(:team).permit(:id, :name, :category_id, :division_id, :season_id, :homecourt_id, :rules, :coaches, :players, :targets, :team_targets, coaches_attributes: [:id], coach_ids: [], player_ids: [], players_attributes: [:id], targets_attributes: [], team_targets_attributes: [])
		end
end
