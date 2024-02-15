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
	before_action :set_team, only: [:index, :show, :roster, :slots, :edit, :edit_roster, :attendance, :targets, :edit_targets, :plan, :edit_plan, :new, :update, :destroy]

	# GET /teams
	# GET /teams.json
	def index
		c_ret = get_retlnk(t_index: true)
		if check_access(roles: [:manager, :coach, :player])
			@teams  = (u_coach? || u_manager?) ? Team.search(@season.id) : current_user.team_list
			title   = helpers.team_title_fields(title: I18n.t("team.many"), search: (u_coach? || u_manager?))
			@title  = create_fields(title)
			@grid   = create_grid(helpers.team_grid(teams: @teams, season: not(@season), add_teams: u_manager?))
			submit  = {kind: "export", url: teams_path(format: :xlsx), working: false} if u_manager?
			@submit = create_submit(close: "back", close_return: c_ret, submit:)
			respond_to do |format|
				format.xlsx {
					f_name = "#{@season.name(safe: true)}-players.xlsx"
					a_desc = "#{I18n.t("player.export")} '#{f_name}'"
					register_action(:exported, a_desc, url: teams_path(retlnk: home_log_path))
					response.headers['Content-Disposition'] = "attachment; filename=#{f_name}"
				}
				format.html { render :index }
			end
		else
			redirect_to c_ret, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/new
	def new
		if check_access(roles: [:manager])
			@eligible_coaches = Coach.active
			@sport  = Sport.fetch(params[:sport_id])
			@team   = Team.new(season_id: params[:season_id] ? params[:season_id] : Season.last.id)
			@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.new")))
			@submit = create_submit(close_return: teams_path(retlnk: @retlnk))
		else
			redirect_to @retlnk, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1
	# GET /teams/1.json
	def show
		if check_access(roles: [:manager, :coach], obj: @team)
			@sport   = @team.sport.specific
			@title   = create_fields(helpers.team_title_fields(title: @team.to_s))
			@coaches = create_fields(helpers.team_coaches)
			if u_manager? or u_coach?
				@links = create_fields(helpers.team_links)
				@grid  = create_fields(helpers.event_list_grid(events: @team.events.short_term, obj: @team, retlnk: team_path(retlnk: @retlnk)))
				submit = ((u_manager? || @team.has_coach(u_coachid)) ? edit_team_path(retlnk: @retlnk) : nil)
			else
				start_date = (params[:start_date] ? params[:start_date] : Date.today.at_beginning_of_month).to_date
				anchorlnk  = team_events_path(@team, retlnk: team_path(retlnk: @retlnk), start_date:)
				@calendar  = CalendarComponent.new(start_date:, events: @team.events, anchor: anchorlnk, obj: @team, user: current_user)
				submit     = nil
			end
			@submit    = create_submit(close: "back", close_return: @retlnk, submit:, frame: (submit ? "modal" : nil))
		else
			redirect_to @retlnk, data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/roster
	def roster
		if check_access(roles: [:manager, :coach])
			title   = helpers.team_title_fields(title: @team.to_s)
			players = @team.players
			title << [{kind: "icon", value: "player.svg", size: "30x30"}, {kind: "label", value: I18n.t("team.roster")}, {kind: "string", value: "(#{players.count} #{I18n.t("player.abbr")})"}]
			@title  = create_fields(title)
			@title  = create_fields(title)
			@grid   = create_grid(helpers.player_grid(players: players.order(:number), obj: @team))
			submit  = (u_manager? || @team.has_coach(u_coachid)) ? edit_roster_team_path(retlnk: @retlnk) : nil
			@submit = create_submit(close: "back", close_return: team_path(retlnk: @retlnk), submit:)
		else
			redirect_to team_path(retlnk: @retlnk), data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/edit_roster
	def edit_roster
		if check_access(roles: [:manager]) || @team.has_coach(u_coachid)
			title = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "player.svg", size: "30x30"}, {kind: "label", value: I18n.t("team.roster_edit")}]
			@title  = create_fields(title)
			@submit = create_submit(close: "cancel", close_return: roster_team_path(retlnk: @retlnk))
			@eligible_players = @team.eligible_players
		else
			redirect_to team_path(retlnk: @retlnk), data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/slots
	def slots
		if check_access(roles: [:manager], obj: @team)
			title   = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "timetable.svg", size: "30x30"}, {kind: "label", value: I18n.t("slot.many")}]
			@fields = create_fields(title)
		else
			redirect_to team_path(retlnk: @retlnk), data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/targets
	def targets
		if check_access(roles: [:manager, :coach])
			global_targets(true)	# get & breakdown global targets
			title = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "target.svg", size: "30x30"}, {kind: "label", value: I18n.t("target.many")}]
			@title  = create_fields(title)
			edit    = ((u_manager? || @team.has_coach(u_coachid)) ? edit_targets_team_path(retlnk: @retlnk) : nil)
			@submit = create_submit(close: "back", close_return: team_path(retlnk: @retlnk), submit: edit)
		else
			redirect_to team_path(retlnk: @retlnk), data: {turbo_action: "replace"}
		end

	end

	# GET /teams/1/edit_targets
	def edit_targets
		if check_access(roles: [:manager]) || @team.has_coach(u_coachid)
			redirect_to("/", data: {turbo_action: "replace"}) unless @team
			global_targets(false)	# get global targets
			title   = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "target.svg", size: "30x30"}, {kind: "label", value: I18n.t("target.edit")}]
			@title  = create_fields(title)
			@submit = create_submit(close: "cancel", close_return: targets_team_path(retlnk: @retlnk))
		else
			redirect_to team_path(retlnk: @retlnk), data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/edit_targets
	def plan
		if check_access(roles: [:manager, :coach])
			plan_targets
			title = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "teamplan.svg", size: "30x30"}, {kind: "label", value: I18n.t("plan.single")}]
			@title = create_fields(title)
			edit    = ((u_manager? || @team.has_coach(u_coachid)) ? edit_plan_team_path(retlnk: @retlnk) : nil)
			@submit = create_submit(close: "back", close_return: team_path(retlnk: @retlnk), submit: edit)
		else
			redirect_to team_path(retlnk: @retlnk), data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/edit_plan
	def edit_plan
		if check_access(roles: [:manager]) || @team.has_coach(u_coachid)
			redirect_to("/", data: {turbo_action: "replace"}) unless @team
			plan_targets
			title   = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "teamplan.svg", size: "30x30"}, {kind: "label", value: I18n.t("plan.edit")}]
			@title  = create_fields(title)
			@submit = create_submit(close: "cancel", close_return: plan_team_path(retlnk: @retlnk))
		else
			redirect_to team_path(retlnk: @retlnk), data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/attendance
	def attendance
		if check_access(roles: [:manager, :coach])
			title  = helpers.team_title_fields(title: @team.to_s)
			title << [{kind: "icon", value: "attendance.svg", size: "30x30"}, {kind: "label", value: I18n.t("calendar.attendance")}]
			@title = create_fields(title)
			a_data = helpers.team_attendance_grid
			if a_data
				@grid = create_grid({title: a_data[:title], rows: a_data[:rows]})
				@att_data = [a_data[:chart]] if a_data
			end
			@submit = create_submit(submit: nil)
		else
			redirect_to team_path(retlnk: @retlnk), data: {turbo_action: "replace"}
		end
	end

	# GET /teams/1/edit
	def edit
		if check_access(roles: [:manager]) || @team.has_coach(u_coachid)
			@eligible_coaches = Coach.active
			@sport  = @team.sport.specific
			@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.edit")))
			@submit = create_submit
		else
			redirect_to team_path(retlnk: @retlnk), data: {turbo_action: "replace"}
		end
	end

	# POST /teams
	# POST /teams.json
	def create
		if check_access(roles: [:manager])
			@team = Team.build(team_params)
			respond_to do |format|
				if @team.save
					a_desc = "#{I18n.t("team.created")} '#{@team.to_s}'"
					register_action(:created, a_desc, url: team_path(@team, retlnk: home_log_path))
					format.html { redirect_to teams_path(season_id: @team.season.id), notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: teams_path(season_id: @team.season.id) }
				else
					@eligible_coaches = Coach.active
					@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.new")))
					@submit = create_submit
					format.html { render :new }
					format.json { render json: @team.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to @retlnk, data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /teams/1
	# PATCH/PUT /teams/1.json
	def update
		if check_access(roles: [:manager]) || @team.has_coach(u_coachid)
			respond_to do |format|
				n_notice = no_data_notice(trail: @team.to_s)
				retshow  = prepare_update_redirect
				if params[:team]
					@team.rebuild(params[:team])
					if @team.modified?
						if @team.save
							a_desc = "#{I18n.t("team.updated")} '#{@team.to_s}'"
							register_action(:updated, a_desc, url: team_path(@team, retlnk: home_log_path))
							format.html { redirect_to retshow, notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
							format.json { redirect_to retshow, status: :created, location: retlnk }
						else
							@eligible_coaches = Coach.active
							@fields = create_fields(helpers.team_form_fields(title: I18n.t("team.edit")))
							@submit = create_submit
							format.html { render :edit, data:{"turbo-frame": "replace"}, notice: helpers.flash_message(@team.errors,"error") }
							format.json { render json: @team.errors, status: :unprocessable_entity }
						end
					else	# no data to save...
						format.html { redirect_to retshow, notice: n_notice, data: {turbo_action: "replace"} }
						format.json { render json: @team.errors, status: :unprocessable_entity }
					end
				else	# no data to save...
					format.html { redirect_to retshow, notice: n_notice, data: {turbo_action: "replace"} }
					format.json { redirect_to retshow, status: :ok, location: retlnk }
				end
			end
		else
			redirect_to retshow, data: {turbo_action: "replace"}
		end
	end

	# DELETE /teams/1
	# DELETE /teams/1.json
	def destroy
		# cannot destroy placeholder teams (id: 0 || -1)
		if @team.id > 0 && ccheck_access(roles: [:manager]) && @team
			t_name = @team.to_s
			@team.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("team.deleted")} '#{t_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to teams_path(retlnk: @retlnk), status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to @retlnk, data: {turbo_action: "replace"}
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

		# defines correct retlnk based on params received
		def get_retlnk(t_index: nil)
			if t_index
				return @season ? seasons_path(season_id: @season.id) : seasons_path
			elsif (rlnk = (param_passed(:retlnk) || param_passed(:team, :retlnk)))
				res = safelink(rlnk)
			elsif (u_coach? || u_manager? || params[:season_id].present?)
				res = teams_path(season_id: @season.id)
			elsif current_user
				res = user_path(current_user)
			end
			res ||= "/"
		end

		# retrieve monthly targets for the team
		def plan_targets
			@months = @team.season.months(true)
			@targets = Array.new
			@months.each { |m| @targets << fetch_targets(m)	}
		end

		# set the right redirect for update depending on params received
		def prepare_update_redirect
			if param_passed(:team, :player_ids)
				return roster_team_path(retlnk: @retlnk)
			elsif param_passed(:team, :team_targets_attributes)
				first_target = team_params[:team_targets_attributes].to_h.first
				if first_target
					if first_target[1]["month"] == "0"
						return targets_team_path(retlnk: @retlnk)
					else
						return plan_team_path(retlnk: @retlnk)
					end
				else
					return team_path(retlnk: @retlnk)
				end
			else
				team_path(retlnk: @retlnk)
			end
		end

		# return array of safe links to redirect
		def safelink(lnk=nil)
			val = [home_log_path, teams_path]
			val << (u_path = current_user ? user_path(current_user) : "/")
			if @season
				val << (t_path = teams_path(season_id: @season.id))
				if @team
					val << team_path(retlnk: t_path)
					val << team_path(retlnk: u_path)
					val << team_path(season_id: @season.id)
					val << plan_team_path(retlnk: t_path)
					val << plan_team_path(retlnk: u_path)
					val << plan_team_path(season_id: @season.id)
					val << roster_team_path(retlnk: t_path)
					val << roster_team_path(retlnk: u_path)
					val << roster_team_path(season_id: @season.id)
					val << targets_team_path(retlnk: t_path)
					val << targets_team_path(retlnk: u_path)
					val << targets_team_path(season_id: @season.id)
				end
			end
			validate_link(lnk, val)
	end

		# Use callbacks to share common setup or constraints between actions.
		def set_team
			@team     = Team.find_by_id(params[:id]) if params[:id]
			s_id      = @team&.season&.id || params[:season_id].presence || session.dig('team_filters', 'season_id')
			@season   = Season.find_by(id: s_id) if s_id
			@season ||= Season.latest || Season.last
			@retlnk   = get_retlnk
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def team_params
			params.require(:team).permit(
				:id,
				:name,
				:sport_id,
				:category_id,
				:division_id,
				:season_id,
				:homecourt_id,
				:rules,
				:coaches,
				:players,
				:retlnk,
				:targets,
				:team_targets,
				coaches_attributes: [:id],
				coach_ids: [],
				player_ids: [],
				players_attributes: [:id],
				targets_attributes: [],
				team_targets_attributes: {}
			)
		end
end
