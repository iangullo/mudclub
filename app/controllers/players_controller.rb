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
class PlayersController < ApplicationController
	include Filterable
	before_action :set_player, only: [:show, :edit, :update, :destroy]

	# GET /players
	# GET /players.json
	def index
		if check_access(roles: [:manager, :coach])
			@players = get_players
			@retlnk  = get_retlnk ||  "/"
			title    = helpers.person_title_fields(title: I18n.t("player.many"), icon: "player.svg", size: "50x50")
			title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('player_filters', 'search'), url: players_path, size: 10}]
			@fields  = create_fields(title)
			@grid    = create_grid(helpers.player_grid(players: @players))
			submit  = {kind: "export", url: players_path(format: :xlsx), working: false} if u_manager?
			@submit = create_submit(close: "back", close_return: @retlnk, submit:)
			respond_to do |format|
				format.xlsx {
					a_desc = "#{I18n.t("player.export")} 'players.xlsx'"
					register_action(:exported, a_desc)
					response.headers['Content-Disposition'] = "attachment; filename=players.xlsx"
				}
				format.html { render :index }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /players/1
	# GET /players/1.json
	def show
		if check_access(roles: [:manager, :coach], obj: @player)
			@retlnk ||= players_path(search: @player.s_name)
			@fields   = create_fields(helpers.player_show_fields(team: params[:team_id] ? Team.find(params[:team_id]) : nil))
			@submit   = create_submit(close: "back", close_return: @retlnk, submit: edit_player_path(@player, retlnk: @retlnk), frame: "modal")
			@grid     = create_grid(helpers.team_grid(teams: @player.team_list))
		else
			redirect_to players_path, data: {turbo_action: "replace"}
		end
	end

	# GET /players/new
	def new
		if check_access(roles: [:manager, :coach])
			@player = Player.new(active: true)
			@player.build_person
			prepare_form(title: I18n.t("player.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /players/1/edit
	def edit
		if check_access(roles: [:manager, :coach], obj: @player)
			prepare_form(title: I18n.t("player.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /players
	# POST /players.json
	def create
		if check_access(roles: [:manager, :coach])
			respond_to do |format|
				@player = Player.new
				@player.rebuild(player_params)	# rebuild player
				retlnk = (get_retlnk || players_path(search: @player.s_name))
				if @player.modified? then	# it is a new player
					if @player.paranoid_create
						link_team(player_params[:team_id].presence)	# try to add it to the team roster
						@player.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("player.created")} '#{@player.to_s}'"
						register_action(:created, a_desc, url: player_path(@player, retlnk: home_log_path))
						format.html { redirect_to player_path(@player, retlnk:), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :created, location: @retlnk }
					else
						prepare_form(title: I18n.t("player.new"))
						format.html { render :new }
						format.json { render json: @player.errors, status: :unprocessable_entity }
					end
				else # player was already in the database
					link_team(player_params[:team_id])	# try to add it to the team roster
					format.html { redirect_to retlnk, notice: helpers.flash_message("#{I18n.t("player.duplicate")} '#{@player.to_s}'"), data: {turbo_action: "replace"} }
					format.json { render :show, status: :duplicate, location: @retlnk }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /players/1
	# PATCH/PUT /players/1.json
	def update
		if check_access(roles: [:manager, :coach], obj: @player)
			respond_to do |format|
				@player.rebuild(player_params)
				@retlnk ||= players_path(search: @player.s_name)
				@retlnk   = player_path(retlnk: @retlnk)
				if @player.modified?
					if @player.save
						@player.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("player.updated")} '#{@player.to_s}'"
						register_action(:updated, a_desc, url: player_path(@player, retlnk: home_log_path))
						format.html { redirect_to @retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :ok, location: @retlnk}
					else
						prepare_form(title: I18n.t("player.edit"))
						format.html { render :edit }
						format.json { render json: @player.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to @retlnk, notice: no_data_notice, data: {turbo_action: "replace"}}
					format.json { render :show, status: :ok, location: @retlnk }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /players/import
	# GET /players/import.json
	def import
		if check_access(roles: [:manager])
			if params[:file].present?
				Player.import(params[:file].presence)	# added to import excel
				a_desc = "#{I18n.t("player.import")} '#{params[:file].original_filename}'"
				register_action(:imported, a_desc, url: players_path(retlnk: home_log_path))
			else
				a_desc = "#{I18n.t("player.import")}: #{I18n.t("status.no_file")}"
			end
			redirect_to players_path, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"}
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /players/1
	# DELETE /players/1.json
	def destroy
		if check_access(roles: [:manager], obj: @player)
			p_name = @player.to_s
			@player.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("player.deleted")} '#{p_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to players_path, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# get player list depending on the search parameter & user role
		def get_players
			if params[:search].present?
				@players = Player.search(params[:search])
			else
				Player.none
			end
		end

		# defines correct retlnk based on params received
		def get_retlnk
			if (rlnk = (param_passed(:retlnk) || param_passed(:player, :retlnk)))
				return safelink(rlnk)
			elsif u_coach? || u_manager?
				return players_path
			elsif current_user
				return user_path(current_user)
			end
		end

		# link a player to a team
		def link_team(team_id)
			if team_id && (team = Team.find(team_id))	# only if we find it
				team.players << @player unless team.has_player(@player.id)
			end
		end

		# Prepare a player form
		def prepare_form(title:)
			@retlnk ||= players_path(search: @player.s_name)	# ensure we have a valid return link
			@title    = create_fields(helpers.person_form_title(@player.person, icon: @player.picture, title:, sex: true))
			@j_fields = create_fields(helpers.player_form_fields(team_id: params[:team_id]))
			@p_fields = create_fields(helpers.person_form_fields(@player.person))
			@parents  = create_fields(helpers.player_form_parents) if @player.person.age < 18
			@submit   = create_submit
		end

		# return array of safe links to redirect
		def safelink(lnk=nil)
			val = [home_log_path, players_path]
			val << (u_path = current_user ? user_path(current_user) : "/")
			val << players_path(search: @player.s_name) if @player
			@player&.teams.each do |team|
				val << roster_team_path(team)
				val << roster_team_path(team, retlnk: teams_path(season_id: team.season_id))
				val << roster_team_path(team, retlnk: u_path)
			end
			validate_link(lnk, val)
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_player
			@player = Player.find_by_id(params[:id]) unless @player&.id==params[:id]
			@retlnk = get_retlnk
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def player_params
			params.require(:player).permit(
				:id,
				:number,
				:active,
				:avatar,
				:retlnk,
				:team_id,
				person_attributes: [
					:id,
					:address,
					:avatar,
					:birthday,
					:dni,
					:email,
					:female,
					:id_back,
					:id_front,
					:name,
					:nick,
					:phone,
					:surname
				],
				teams_attributes: [:id, :_destroy],
				parents_attributes: [
					:id,
					:_destroy,
					person_attributes: [:id, :name, :surname, :email, :phone]
				]
			)
		end
end
