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
class PlayersController < ApplicationController
	include Filterable
	before_action :set_player, only: [:show, :edit, :update, :destroy]

	# GET /clubs/x/players
	# GET /clubs/x/players.json
	def index
		if check_access(obj: Club.find(@clubid)) || (u_coach? && u_clubid==@clubid)
			@players = Player.search(params[:search], current_user)
			title    = helpers.person_title_fields(title: I18n.t("player.many"), icon: "player.svg", size: "50x50")
			title << [{kind: "search-text", key: :search, value: params[:search].presence || session.dig('coach_filters','search'), url: club_players_path(@clubid)}]
			@fields = create_fields(title)
			@grid   = create_grid(helpers.player_grid(players: @players))
			submit  = {kind: "export", url: club_players_path(@clubid, format: :xlsx), working: false} if u_manager?
			@submit = create_submit(close: "back", retlnk: club_path(@clubid), submit:)
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
		if (u_manager? && [nil, @clubid].include?(u_clubid)) || (u_coach? && u_clubid==@clubid) ||  check_access(obj: @player)
			@fields = create_fields(helpers.player_show_fields(team: Team.find_by_id(@teamid)))
			@grid   = create_grid(helpers.team_grid(teams: @player.team_list))
			submit  = (u_manager? || u_coach? || u_playerid==@player.id) ? edit_player_path(@player, team_id: @teamid, rdx: @rdx) : nil
			@submit = create_submit(close: "back", retlnk: get_retlnk, submit:, frame: "modal")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /players/new
	def new
		if check_access(roles: [:manager, :coach])
			get_player_context
			@player = Player.new(active: true)
			@player.build_person
			prepare_form(title: I18n.t("player.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /players/1/edit
	def edit
		if (u_manager? && [nil, @clubid].include?(u_clubid)) || (u_coach? && u_clubid==@clubid) ||  check_access(obj: @player)
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
				get_player_context
				@player = Player.new
				@player.rebuild(player_params)	# rebuild player
				if @player.modified? then	# it is a new player
					if @player.paranoid_create
						retlnk = player_path(@player, rdx: @rdx, team_id: @teamid)
						link_team(player_params[:team_id].presence)	# try to add it to the team roster
						@player.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("player.created")} '#{@player.to_s}'"
						register_action(:created, a_desc, url: player_path(@player, rdx: 2))
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :created, location: retlnk }
					else
						prepare_form(title: I18n.t("player.new"))
						format.html { render :new }
						format.json { render json: @player.errors, status: :unprocessable_entity }
					end
				else # player was already in the database
					retlnk = player_path(@player, rdx: @rdx, team_id: @teamid)
					link_team(@teamid)	# try to add it to the team roster
					format.html { redirect_to retlnk, notice: helpers.flash_message("#{I18n.t("player.duplicate")} '#{@player.to_s}'"), data: {turbo_action: "replace"} }
					format.json { render :show, status: :duplicate, location: retlnk }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /players/1
	# PATCH/PUT /players/1.json
	def update
		retlnk = player_path(@player, rdx: @rdx, team_id: @teamid)
		if (u_manager? && [nil, @clubid].include?(u_clubid)) || (u_coach? && u_clubid==@clubid) ||  check_access(obj: @player)
			respond_to do |format|
				@player.rebuild(player_params)
				if @player.modified?
					if @player.save
						@player.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("player.updated")} '#{@player.to_s}'"
						register_action(:updated, a_desc, url: player_path(@player, rdx: 2))
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :ok, location: retlnk}
					else
						prepare_form(title: I18n.t("player.edit"))
						format.html { render :edit }
						format.json { render json: @player.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to retlnk, notice: no_data_notice, data: {turbo_action: "replace"}}
					format.json { render :show, status: :ok, location: r_path }
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
				register_action(:imported, a_desc, url: players_path(rdx: 2))
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
		# cannot destroy placeholder player (id ==0)
		if @player.id != 0 && check_access(obj: Club.find_by_id(@player.club_id))
			p_name = @player.to_s
			@player.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("player.deleted")} '#{p_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to get_retlnk, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# prepare playyer action context
		def get_player_context
			@teamid = p_teamid
			@clubid = @player&.club_id
		end

		# defines correct retlnk based on params received
		# should be called only by index/show
		def get_retlnk
			return home_log_path if @rdx&.to_i== 2	# return to log_path
			return roster_team_path(id: @teamid, rdx: @rdx) if @teamid
			return club_players_path(@player.club_id, search: @player.s_name, rdx: 0) if @player
			return (@clubid ? club_players_path(@clubid, rdx: 0) : u_path)
		end

		# link a player to a team
		def link_team(team_id)
			if team_id && (team = Team.find(team_id))	# only if we find it
				@player.teams << team unless @player.teams.include?(team)
				team.players << @player unless team.has_player(@player.id)
			end
		end

		# Prepare a player form
		def prepare_form(title:)
			@title    = create_fields(helpers.person_form_title(@player.person, icon: @player.picture, title:, sex: true))
			@j_fields = create_fields(helpers.player_form_fields)
			@p_fields = create_fields(helpers.person_form_fields(@player.person))
			@parents  = create_fields(helpers.player_form_parents) if @player.person.age < 18
			@submit   = create_submit
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_player
			@player = Player.find_by_id(params[:id]) unless @player&.id==params[:id]
			get_player_context
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def player_params
			params.require(:player).permit(
				:id,
				:active,
				:active?,
				:avatar,
				:club_id,
				:event_id,
				:number,
				:rdx,
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
