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
# Managament of players -typically linked to a club
class PlayersController < ApplicationController
	include Filterable
	before_action :set_player, only: [ :show, :edit, :update, :destroy ]

	# GET /clubs/x/players
	# GET /clubs/x/players.json
	def index
		if player_manager?
			@players = Player.search(params[:search], current_user)
			respond_to do |format|
				format.xlsx do
					a_desc = "#{I18n.t("player.export")} 'players.xlsx'"
					register_action(:exported, a_desc)
					response.headers["Content-Disposition"] = "attachment; filename=players.xlsx"
				end
				format.html do
					title  = helpers.person_title_fields(title: I18n.t("player.many"), icon: { concept: "player", options: { namespace: "sport", size: "50x50" } })
					title << [ { kind: :search_text, key: :search, value: params[:search].presence || session.dig("coach_filters", "search"), url: club_players_path(@clubid, rdx: @rdx) } ]
					page   = paginate(@players)	# paginate results
					table  = helpers.player_table(players: page)
					submit = { kind: :export, url: club_players_path(@clubid, format: :xlsx), working: false } if u_manager? || u_secretary?
					retlnk = base_lnk(club_path(@clubid, rdx: @rdx))
					create_index(title:, table:, page:, retlnk:, submit:)
					render :index
				end
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /players/1
	# GET /players/1.json
	def show
		if @player && (player_manager? || check_access(obj: @player))
			@fields = create_fields(helpers.player_show_fields(team: Team.find_by_id(@teamid)))
			@table  = create_table(helpers.team_table(teams: @player.team_list))
			submit  = edit_player_path(@player, team_id: @teamid, rdx: @rdx)
			@submit = create_submit(close: :back, retlnk: crud_return, submit:, frame: "modal")
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /players/new
	def new
		if player_manager?
			get_player_context
			@player = Player.new(club_id: u_clubid)
			@player.build_person
			prepare_form("new")
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /players/1/edit
	def edit
		if @player && (player_manager? || check_access(obj: @player))
			prepare_form("edit")
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# POST /players
	# POST /players.json
	def create
		if player_manager?
			respond_to do |format|
				get_player_context
				@player = Player.new
				@player.rebuild(player_params)	# rebuild player
				if @player.modified? then	# it is a new player
					if @player.paranoid_create
						retlnk = player_path(@player, rdx: @rdx, team_id: @teamid)
						link_team(player_params[:team_id].presence)	# try to add it to the team roster
						@player.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("player.created")} '#{@player.to_s(style: 1)}'"
						register_action(:created, a_desc, url: player_path(@player, rdx: 2))
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
						format.json { render :show, status: :created, location: retlnk }
					else
						prepare_form("new")
						format.html { render :new }
						format.json { render json: @player.errors, status: :unprocessable_entity }
					end
				else # player was already in the database
					retlnk = player_path(@player, rdx: @rdx, team_id: @teamid)
					link_team(@teamid)	# try to add it to the team roster
					format.html { redirect_to retlnk, notice: helpers.flash_message("#{I18n.t("player.duplicate")} '#{@player.to_s(style: 1)}'"), data: { turbo_action: "replace" } }
					format.json { render :show, status: :duplicate, location: retlnk }
				end
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# PATCH/PUT /players/1
	# PATCH/PUT /players/1.json
	def update
		if @player && (player_manager? || check_access(obj: @player))
			retlnk = player_path(@player, rdx: @rdx, team_id: @teamid)
			respond_to do |format|
				@player.rebuild(player_params)
				if @player.modified?
					if @player.save
						@player.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("player.updated")} '#{@player.to_s(style: 1)}'"
						register_action(:updated, a_desc, url: player_path(@player, rdx: 2))
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
						format.json { render :show, status: :ok, location: retlnk }
					else
						prepare_form("edit")
						format.html { render :edit }
						format.json { render json: @player.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to retlnk, notice: no_data_notice, data: { turbo_action: "replace" } }
					format.json { render :show, status: :ok, location: retlnk }
				end
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /players/import
	# GET /players/import.json
	def import
		if check_access(roles: [ :manager, :secretary ])
			if params[:file].present?
				Player.import(params[:file].presence)	# added to import excel
				a_desc = "#{I18n.t("player.import")} '#{params[:file].original_filename}'"
				register_action(:imported, a_desc, url: players_path(rdx: 2))
			else
				a_desc = "#{I18n.t("player.import")}: #{I18n.t("status.no_file")}"
			end
			redirect_to players_path(rdx: @rdx), notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" }
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# DELETE /players/1
	# DELETE /players/1.json
	def destroy
		# cannot destroy placeholder player (id ==0)
		if @player && @player.id != 0
			p_name = @player.to_s(style: 1)
			if @teamid	# we're calling froma roster view --> remove from team roster
				act   = "removed"
				@team = Team.find(@teamid)
				@team.players.delete(@player) if team_manager?
			elsif club_manager?(@player.club)	# calling from a players index --> deactivate
				act   = "deactivated"
				@player.update(club_id: nil)
			end
			respond_to do |format|
				a_desc = "#{I18n.t("player.#{act}")} '#{p_name}'"
				register_action(:deleted, a_desc, url: player_path(@player, rdx: 2))
				format.html { redirect_to crud_return, status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	private
		# wrapper to set return link for CRUD operations
		def crud_return
			return roster_team_path(id: @teamid, rdx: @rdx) if @teamid
			return club_players_path(u_clubid, search: @player.s_name, rdx: @rdx) if @player
			(@clubid ? club_players_path(@clubid, rdx: @rdx) : u_path)
		end

		# prepare player action context
		def get_player_context
			@teamid = p_teamid
			@clubid = @player&.club_id
		end

		# link a player to a team
		def link_team(team_id)
			if team_id && (team = Team.find(team_id))	# only if we find it
				@player.teams << team unless @player.teams.include?(team)
				team.players << @player unless team.has_player(@player.id)
			end
		end

		# wrapper to check if a user can edit players
		def player_manager?
			((u_manager? || u_coach? || u_secretary?) && [ nil, u_clubid ].include?(@clubid))
		end

		# Prepare a player form
		def prepare_form(action)
			@title    = create_fields(helpers.person_form_title(@player.person, icon: @player.picture, title: I18n.t("player.#{action}"), sex: true))
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
				teams_attributes: [ :id, :_destroy ],
				parents_attributes: [
					:id,
					:_destroy,
					person_attributes: [ :id, :name, :surname, :email, :phone ]
				]
			)
		end
end
