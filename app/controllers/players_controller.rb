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
	#skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_player, only: [:show, :edit, :update, :destroy]

	# GET /players
	# GET /players.json
	def index
		if check_access(roles: [:admin, :coach])
			@players = get_players
			title    = helpers.player_title_fields(title: I18n.t("player.many"))
			title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('player_filters', 'search'), url: players_path, size: 10}]
			@fields  = create_fields(title)
			@grid    = create_grid(helpers.player_grid(players: @players))
			respond_to do |format|
				format.xlsx {
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
		if check_access(roles: [:admin, :coach], obj: @player)
			@fields = create_fields(helpers.player_show_fields(team: params[:team_id] ? Team.find(params[:team_id]) : nil))
			@submit = create_submit(submit: (current_user.admin? or current_user.is_coach? or current_user.person.player_id==@player.id) ? edit_player_path(@player, retlnk: params[:retlnk]) : nil, frame: "modal")
		else
			redirect_to players_path, data: {turbo_action: "replace"}
		end
	end

	# GET /players/new
	def new
		if check_access(roles: [:admin, :coach])
			@player = Player.new(active: true)
			@player.build_person
			prepare_form(title: I18n.t("player.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /players/1/edit
	def edit
		if check_access(roles: [:admin, :coach], obj: @player)
			prepare_form(title: I18n.t("player.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /players
	# POST /players.json
	def create
		if check_access(roles: [:admin, :coach])
			respond_to do |format|
				@player = Player.new
				@player.rebuild(player_params)	# rebuild player
				if @player.is_duplicate? then
					format.html { redirect_to players_path(search: @player.s_name), notice: helpers.flash_message("#{I18n.t("player.duplicate")} '#{@player.to_s}'"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :duplicate, location: players_path(search: @player.s_name) }
				else
					@player.person.save unless @player.person.persisted?
					if @player.save
						if @player.person.player_ind != @player.id
							@player.person.player_id = @player.id
							@player.person.save
						end
						format.html { redirect_to players_path(search: @player.s_name), notice: helpers.flash_message("#{I18n.t("player.created")} '#{@player.to_s}'", "success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: players_path(search: @player.s_name) }
					else
						format.html { render :new }
						format.json { render json: @player.errors, status: :unprocessable_entity }
					end
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /players/1
	# PATCH/PUT /players/1.json
	def update
		if check_access(roles: [:admin, :coach], obj: @player)
			respond_to do |format|
				@player.rebuild(player_params)
				if @player.save
					format.html { redirect_to player_params[:retlnk], notice: helpers.flash_message("#{I18n.t("player.updated")} '#{@player.to_s}'", "success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :ok, location: players_path(search: @player.s_name) }
				else
					format.html { render :edit }
					format.json { render json: @player.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /players/import
	# GET /players/import.json
	def import
		if check_access(roles: [:admin])
			Player.import(params[:file])	# added to import excel
			format.html { redirect_to players_path, notice: helpers.flash_message("#{I18n.t("player.import")} '#{params[:file].original_filename}'", "success"), data: {turbo_action: "replace"} }
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /players/1
	# DELETE /players/1.json
	def destroy
		if check_access(roles: [:admin], obj: @player)
			p_name = @player.to_s
			unlink_person
			@player.destroy
			respond_to do |format|
				format.html { redirect_to players_path, status: :see_other, notice: helpers.flash_message("#{I18n.t("player.deleted")} '#{p_name}'"), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# Prepare a player form
		def prepare_form(title:)
			@title      = create_fields(helpers.player_form_title(title:))
			@j_fields_1 = create_fields(helpers.player_form_fields_1(retlnk: params[:retlnk]))
			@j_fields_2 = create_fields(helpers.player_form_fields_2(avatar: @player.avatar))
			@p_fields   = create_fields(helpers.player_form_person(person: @player.person))
			@submit     = create_submit
		end

		# De-couple from associated person
		def unlink_person
			if @player.person.try(:player_id) == @player.id
				p = @player.person
				p.player=Player.find(0)   # map to empty player
				p.save
				@player.person_id = 0    # map to empty person
			end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_player
			@player = Player.find_by_id(params[:id]) unless @player.try(:id)==params[:id]
		end

		# get player list depending on the search parameter & user role
		def get_players
			if (params[:search] != nil) and (params[:search].length > 0)
				@players = Player.search(params[:search])
			else
				Player.none
			end
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def player_params
			params.require(:player).permit(:id, :number, :active, :avatar, :retlnk, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :female, :email, :phone], teams_attributes: [:id, :_destroy])
		end
end
