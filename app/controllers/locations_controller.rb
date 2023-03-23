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
class LocationsController < ApplicationController
	#skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_locations, only: [:index, :show, :edit, :new, :update, :destroy, :locations]

	# GET /locations
	# GET /locations.json
	def index
		if check_access(roles: [:admin, :coach])
			@season = Season.find(params[:season_id]) if params[:season_id]
			title  = helpers.location_title_fields(title: I18n.t("location.many"))
			title << [@season ? {kind: "label", value: @season.name} : {kind: "search-text", key: :search, value: params[:search], url: locations_path}]
			@fields = create_fields(title)
			@grid   = create_grid(helpers.location_grid)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /locations/1
	# GET /locations/1.json
	def show
		if check_access(roles: [:users], obj: @location)
			@fields = create_fields(helpers.location_show_fields)
			@submit = create_submit(submit: (u_admin? or u_coach?) ? edit_location_path(@location) : nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /locations/1/edit
	def edit
		if check_access(roles: [:admin, :coach], obj: @location)
			prepare_form(title: I18n.t("location.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /locations/new
	def new
		if check_access(roles: [:admin, :coach])
			@location = Location.new(name: t("location.default")) unless @location
			prepare_form(title: I18n.t("location.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /locations
	# POST /locations.json
	def create
		if check_access(roles: [:admin, :coach])
			respond_to do |format|
				@season   = Season.find(params[:location][:season_id]) if params[:location][:season_id]
				@location = Location.new
				@location.rebuild(location_params) # rebuild @location
				if @location.id!=nil  # @location is already stored in database
					if @season
						@season.locations |= [@location]
						format.html { redirect_to season_locations_path(@season), notice: helpers.flash_message("#{I18n.t("location.created")} #{@season.name} => '#{@location.name}'"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: season_locations_path(@season) }
					else
						format.html { render @location, notice: {kind: "info", message: t(:loc_created) + "'#{@location.name}'"}}
						format.json { render :show, :created, location: locations_url(@location) }
					end
				else
					if @location.save
						@season.locations |= [@location] if @season
						format.html { redirect_to @season ? season_locations_path(@season) : locations_url, notice: helpers.flash_message("#{I18n.t("location.created")} '#{@location.name}'", "success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: locations_url }
					else
						format.html { render :new }
						format.json { render json: @location.errors, status: :unprocessable_entity }
					end
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /locations/1 or /locations/1.json
	def update
		if check_access(roles: [:admin, :coach], obj: @location)
			respond_to do |format|
				@location.rebuild(location_params)
				if @location.id!=nil  # we have location to save
					if @location.update(location_params)  # try to save
						@season.locations |= [@location] if @season
						format.html { redirect_to @season ? seasons_path(@season) : locations_path, notice: helpers.flash_message("#{I18n.t("location.updated")} '#{@location.name}'", "success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: locations_path }
					else
						format.html { redirect_to edit_location_path(@location), data: {turbo_action: "replace"} }
						format.json { render json: @location.errors, status: :unprocessable_entity }
					end
				else
					format.html { render @season ? season_locations_path(@season) : locations_path }
					format.json { render :index, status: :unprocessable_entity, location: locations_path }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /locations/1
	# DELETE /locations/1.json
	def destroy
		if check_access(roles: [:admin], obj: @location)
			respond_to do |format|
				l_name = @location.name
				if @season
					@season.locations.delete(@location)
					@locations = @season.locations
					format.html { redirect_to season_locations_path(@season), status: :see_other, notice: helpers.flash_message("#{I18n.t("location.deleted")} #{@season.name} => '#{l_name}'"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: season_locations_path(@season) }
				else
					@location.scrub
					@location.delete
					format.html { redirect_to locations_path, status: :see_other, notice: helpers.flash_message("#{I18n.t("location.deleted")} '#{l_name}'") }
					format.json { render :show, :created, location: locations_url(@location) }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

private
	# ensure internal variables are well defined
	def set_locations
		if params[:season_id]
			@season = Season.find(params[:season_id]) unless @season.try(:id)==params[:season_id]
			@locations = @season.locations.order(:name)
			@eligible_locations = @season.eligible_locations
		else
			@locations = Location.search(params[:search]).order(:name)
			@season    = (params[:location][:season_id] ? Season.find(params[:location][:season_id]) : nil) if params[:location]
		end
		if params[:id]
			@location = Location.find_by_id(params[:id]) unless @location.try(:id)==params[:id]
		end
	end

	# prepare ViewComponents for a Location edit/new form
	def prepare_form(title:)
		@fields = create_fields(helpers.location_form_fields(title:))
		@submit = create_submit
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def location_params
		params.require(:location).permit(:id, :name, :gmaps_url, :practice_court, :season_id, seasons: [], season_locations: [] , seasons_attributes: [:id, :_destroy])
	end
end
