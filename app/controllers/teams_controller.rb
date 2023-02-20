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
	skip_before_action :verify_authenticity_token, :only => [:create, :edit, :new, :update, :check_reload]
	before_action :set_team, only: [:index, :show, :roster, :slots, :edit, :edit_roster, :attendance, :targets, :edit_targets, :plan, :edit_plan, :new, :update, :destroy]

	# GET /teams
	# GET /teams.json
	def index
		check_access(roles: [:admin, :coach])
		@title = helpers.team_title_fields(title: I18n.t("team.many"), search: true)
		@grid  = helpers.team_grid(teams: @teams, season: not(@season), add_teams: current_user.admin?)
	end

	# GET /teams/new
	def new
		check_access(roles: [:admin], returl: teams_path)
	 	@team = Team.new(season_id: params[:season_id] ? params[:season_id] : Season.last.id)
		@eligible_coaches = Coach.active
		@form_fields      = helpers.team_form_fields(title: I18n.t("team.new"), team: @team, eligible_coaches: @eligible_coaches)
	end

	# GET /teams/1
	# GET /teams/1.json
	def show
		check_access(roles: [:admin, :coach], obj: @team, returl: @team)
		@title = helpers.team_title_fields(title: @team.to_s, team: @team)
		@links = helpers.team_links(team: @team)
		@grid  = helpers.event_grid(events: @team.events.short_term, obj: @team, retlnk: team_path(@team))
	end

	# GET /teams/1/roster
	def roster
		check_access(roles: [:admin, :coach], returl: @team)
		@title = helpers.team_title_fields(title: @team.to_s, team: @team)
		@title << [{kind: "icon", value: "player.svg", size: "30x30"}, {kind: "label", value: I18n.t("team.roster")}]
		@grid  = helpers.player_grid(players: @team.players.active.order(:number), obj: @team)
	end

	# GET /teams/1/edit_roster
	def edit_roster
		check_access(roles: [:admin], obj: @team, returl: @team)
		if current_user.present?
			if current_user.admin? or @team.has_coach(current_user.person.coach_id)
				@title = helpers.team_title_fields(title: @team.to_s, team: @team)
				@title << [{kind: "icon", value: "player.svg", size: "30x30"}, {kind: "label", value: I18n.t("team.roster_edit")}]
				@eligible_players = @team.eligible_players
			else
				redirect_to @team, data: {turbo_action: "replace"}
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/slots
	def slots
		check_access(roles: [:admin, :coach], returl: @team)
		@title = helpers.team_title_fields(title: @team.to_s, team: @team)
		@title << [{kind: "icon", value: "timetable.svg", size: "30x30"}, {kind: "label", value: I18n.t("slot.many")}]
	end

	# GET /teams/1/targets
	def targets
		check_access(roles: [:admin, :coach], returl: @team)
		redirect_to "/" unless @team
		global_targets(true)	# get & breakdown global targets
		@title = helpers.team_title_fields(title: @team.to_s, team: @team)
		@title << [{kind: "icon", value: "target.svg", size: "30x30"}, {kind: "label", value: I18n.t("target.many")}]
	end

	# GET /teams/1/edit_targets
	def edit_targets
		check_access(roles: [:admin], obj: @team, returl: @team)
		redirect_to("/", data: {turbo_action: "replace"}) unless @team
		global_targets(false)	# get global targets
		@title = helpers.team_title_fields(title: @team.to_s, team: @team)
		@title << [{kind: "icon", value: "target.svg", size: "30x30"}, {kind: "label", value: I18n.t("target.edit")}]
	end

	# GET /teams/1/edit_targets
	def plan
		check_access(roles: [:admin, :coach], returl: @team)
		redirect_to "/" unless @team
		plan_targets
		@title = helpers.team_title_fields(title: @team.to_s, team: @team)
		@title << [{kind: "icon", value: "teamplan.svg", size: "30x30"}, {kind: "label", value: I18n.t("plan.single")}]
		@edit = edit_plan_team_path if @team.has_coach(current_user.person.coach_id)
	end

	# GET /teams/1/edit_plan
	def edit_plan
		check_access(roles: [:admin], obj: @team, returl: @team)
		redirect_to("/", data: {turbo_action: "replace"}) unless @team
		plan_targets
		@title = helpers.team_title_fields(title: @team.to_s, team: @team)
		@title << [{kind: "icon", value: "teamplan.svg", size: "30x30"}, {kind: "label", value: I18n.t("plan.edit")}]
	end

	# GET /teams/1/attendance
	def attendance
		check_access(roles: [:admin, :coach], returl: @team)
		@title = helpers.team_title_fields(title: @team.to_s, team: @team)
		@title << [{kind: "icon", value: "attendance.svg", size: "30x30"}, {kind: "label", value: I18n.t("calendar.attendance")}]
		@grid  = helpers.team_attendance_grid(team: @team)
		@att_data = [@grid[:chart]]
	end

	# GET /teams/1/edit
	def edit
		check_access(roles: [:admin], obj: @team, returl: @team)
		@eligible_coaches = Coach.active
		@form_fields      = helpers.team_form_fields(title: I18n.t("team.edit"), team: @team, eligible_coaches: @eligible_coaches)
	end

	# POST /teams
	# POST /teams.json
	def create
		check_access(roles: [:admin], returl: teams_path)
		@team = Team.new(team_params)
		respond_to do |format|
			if @team.save
				format.html { redirect_to teams_path, notice: helpers.flash_message("#{I18n.t("team.created")} '#{@team.to_s}'","success"), data: {turbo_action: "replace"} }
				format.json { render :index, status: :created, location: teams_path }
			else
				format.html { render :new }
				format.json { render json: @team.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /teams/1
	# PATCH/PUT /teams/1.json
	def update
		check_access(roles: [:admin], obj: @team, returl: @team)
		respond_to do |format|
			if params[:team]
				retlnk = params[:team][:retlnk]
				@team.rebuild(params[:team])
					if @team.save
					format.html { redirect_to retlnk, notice: helpers.flash_message("#{I18n.t("team.updated")} '#{@team.to_s}'","success"), data: {turbo_action: "replace"} }
					format.json { redirect_to retlnk, status: :created, location: retlnk }
				else
					@eligible_coaches = Coach.active
					@form_fields      = form_fields(I18n.t("team.edit"))
					format.html { render :edit, data:{"turbo-frame": "replace"}, notice: helpers.flash_message("#{I18n.t("status.no_data")} (#{@team.to_s})","error") }
					format.json { render json: @team.errors, status: :unprocessable_entity }
				end
			else	# no data to save...
				format.html { redirect_to @team, notice: helpers.flash_message("#{I18n.t("status.no_data")} (#{@team.to_s})"), data: {turbo_action: "replace"} }
				format.json { render json: @team.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /teams/1
	# DELETE /teams/1.json
	def destroy
		check_access(roles: [:admin], returl: teams_path)
		t_name = @team.to_s
		erase_links
		@team.destroy
		respond_to do |format|
			format.html { redirect_to teams_path, status: :see_other, notice: {kind: "success", message: "#{I18n.t("team.deleted")} '#{t_name}'"}, data: {turbo_action: "replace"} }
			format.json { head :no_content }
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

		# remove dependent records prior to deleting
		def erase_links
			@team.slots.each { |slot| slot.delete }	# training slots
			@team.targets.each { |tgt| tgt.delete }	# team targets & coaching plan
			@team.events.each { |event|							# associated events
				event.tasks.each { |task| task.delete }
				#event.match.delete if event.match
				event.delete
			}
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_team
			@teams = Team.search(params[:season_id] ? params[:season_id] : session.dig('team_filters', 'season_id'))
			if params[:id]=="coaching"
				@team = current_user.coach.teams.first
			else
				@team = Team.find(params[:id]) if params[:id]
			end
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def team_params
			params.require(:team).permit(:id, :name, :category_id, :division_id, :season_id, :homecourt_id, :rules, :coaches, :players, :targets, :team_targets, coaches_attributes: [:id], coach_ids: [], player_ids: [], players_attributes: [:id], targets_attributes: [], team_targets_attributes: [])
		end
end
