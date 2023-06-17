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
class SeasonsController < ApplicationController
	#skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_season, only: [:index, :edit, :update, :destroy, :locations]

	# GET /seasons
	# GET /seasons.json
	def index
		if check_access(roles: [:admin], obj: @season)
			@events = Event.short_term.for_season(@season).non_training
			title   = helpers.season_title_fields(title: I18n.t("season.single"), cols: 2)
			title << [
				{kind: "search-collection", key: :search, url: seasons_path, options: Season.real.order(start_date: :desc)},
				helpers.button_field({kind: "add", url: new_season_path, label: I18n.t("action.create"), frame: "modal"})
			]
			@fields = create_fields(title)
			@links  = create_fields(helpers.season_links)
			@grid   = create_fields(helpers.event_list_grid(events: @events, obj: @season, retlnk: seasons_path))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /seasons/1/edit
	def edit
		if check_access(roles: [:admin], obj: @season)
			@eligible_locations = @season.eligible_locations
			prepare_form(title: I18n.t("season.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /seasons/new
	def new
		if check_access(roles: [:admin])
			@season = Season.new(start_date: Date.today, end_date: Date.today)
			prepare_form(title: I18n.t("season.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /seasons
	# POST /seasons.json
	def create
		if check_access(roles: [:admin])
			@season = Season.new(season_params)
			@eligible_locations = @season.eligible_locations
			respond_to do |format|
				if @season.save
					a_desc = "#{I18n.t("season.created")} '#{@season.name}'"
					register_action(:created, a_desc)
					format.html { redirect_to seasons_path(@season), notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: seasons_path }
				else
					prepare_form(title: I18n.t("season.new"))
					format.html { render :new }
					format.json { render json: @season.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /seasons/1
	# PATCH/PUT /seasons/1.json
	def update
		if check_access(roles: [:admin, :coach], obj: @season)
			respond_to do |format|
				check_locations
				@season.rebuild(season_params)
				if @season.changed?
					if @season.save
						a_desc = "#{I18n.t("season.updated")} '#{@season.name}'"
						register_action(:updated, a_desc)
						format.html { redirect_to seasons_path(@season), notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: seasons_path}
					else
						@eligible_locations = @season.eligible_locations
						prepare_form(title: I18n.t("season.edit"))
						format.html { render :edit }
						format.json { render json: @season.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to seasons_path(@season), notice: no_data_notice, data: {turbo_action: "replace"} }
					format.json { render :index, status: :unprocessable_entity, location: seasons_path(@season) }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /seasons/1
	# DELETE /seasons/1.json
	def destroy
		if check_access(roles: [:admin], obj: @season)
			s_name = @season.name
			@season.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("season.deleted")} '#{s_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to seasons_path, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		def check_locations
			if params[:season][:locations_attributes]
				params[:season][:locations_attributes].each { |loc|
					if loc[1][:_destroy] == "1"
						@season.locations.delete(loc[1][:id].to_i)
					else
						l = Location.find(loc[1][:id].to_i)
						@season.locations ? @season.locations << l : @season.locations |= l
					end
				}
			end
		end

		def set_season
			if params[:search]
				@season = Season.search(params[:search])
			elsif params[:id]
				@season = Season.find_by_id(params[:id]) unless @season&.id==params[:id]
			else
				@season = Season.latest
				@season = Season.last unless @season
			end
		end

		# prepare fields for new/edit season
		def prepare_form(title:)
			@fields = create_fields(helpers.season_form_fields(title:))
			@submit = create_submit
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def season_params
			params.require(:season).permit(:id, :start_date, :end_date, locations_attributes: [:id, :_destroy], locations: [], season_locations: [])
		end
end
