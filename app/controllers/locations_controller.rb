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
		if check_access(roles: [:manager, :coach])
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
		if check_access(roles: [:user])
			@fields = create_fields(helpers.location_show_fields)
			@submit = create_submit(submit: (u_manager? or u_coach?) ? edit_location_path(@location) : nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /locations/1/edit
	def edit
		if check_access(roles: [:manager, :coach])
			prepare_form(title: I18n.t("location.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /locations/new
	def new
		if check_access(roles: [:manager, :coach])
			@location = Location.new(name: t("location.default")) unless @location
			prepare_form(title: I18n.t("location.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /locations
	# POST /locations.json
	def create
		if check_access(roles: [:manager, :coach])
			respond_to do |format|
				@season   = Season.find(params[:location][:season_id]) if params[:location][:season_id]
				@location = Location.new
				@location.rebuild(location_params) # rebuild @location
				a_desc    = "#{I18n.t("location.created")} #{@season&.name} => '#{@location.name}'"
				u_notice  = helpers.flash_message(a_desc, "success")
				posturl   = @season ? season_locations_path(@season) : locations_path
				if @location.id!=nil  # @location is already stored in database
					@season.locations |= [@location] if @season
					register_action(:created, a_desc, url: location_path(@location), modal: true)
					format.html { redirect_to posturl, notice: u_notice, data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: posturl }
				elsif @location.save # attempt to save a new one
					@season.locations |= [@location] if @season
					register_action(:created, a_desc, url: location_path(@location), modal: true)
					format.html { redirect_to posturl, notice: u_notice, data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: posturl }
				else
					prepare_form(title: I18n.t("location.new"))
					format.html { render :new }
					format.json { render json: @location.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /locations/1 or /locations/1.json
	def update
		if check_access(roles: [:manager, :coach])
			respond_to do |format|
				@location.rebuild(location_params)
				retlnk = @season ? season_locations_path(@season) : locations_path
				if @location.id!=nil  # we have location to save
					a_desc = "#{I18n.t("location.updated")} '#{@location.name}'"
					if @location.changed?
						if @location.save  # try to save
							register_action(:updated, a_desc, url: location_path(@location), modal: true)
							@season.locations |= [@location] if @season
							format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
							format.json { render :index, status: :created, location: locations_path }
						else
							format.html { redirect_to edit_location_path(@location), data: {turbo_action: "replace"} }
							format.json { render json: @location.errors, status: :unprocessable_entity }
						end
					elsif @season&.locations&.exclude?(@location)
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						@season.locations << @location
					else
						format.html { redirect_to retlnk, notice: no_data_notice, data: {turbo_action: "replace"} }
						format.json { render :index, status: :unprocessable_entity, location: locations_path }
					end
				else
					prepare_form(title: I18n.t("location.edit"))
					format.html { render retlnk }
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
		if check_access(roles: [:manager])
			respond_to do |format|
				l_name = @location.name
				a_desc = "#{I18n.t("location.deleted")} #{@season&.name} => '#{l_name}'"
				register_action(:deleted, a_desc)
				if @season
					@season.locations.delete(@location)
					@locations = @season.locations
					format.html { redirect_to season_locations_path(@season), status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: season_locations_path(@season) }
				else
					@location.destroy
					format.html { redirect_to locations_path, status: :see_other, notice: helpers.flash_message(a_desc) }
					format.json { render :show, :created, location: locations_path(@location) }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

private
	# ensure internal variables are well defined
	def set_locations
		if params[:season_id].present?
			@season             = Season.find(params[:season_id]) unless @season&.id==params[:season_id]
			@locations          = @season.locations.order(:name)
			@eligible_locations = @season.eligible_locations
		else
			@locations = Location.search(params[:search]).order(:name)
			@season    = (params[:location][:season_id] ? Season.find(params[:location][:season_id]) : nil) if params[:location]
		end
		if params[:id]
			@location = Location.find_by_id(params[:id]) unless @location&.id==params[:id]
		end
	end

	# prepare ViewComponents for a Location edit/new form
	def prepare_form(title:)
		@fields = create_fields(helpers.location_form_fields(title:))
		@submit = create_submit
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def location_params
		params.require(:location).permit(
			:id,
			:name,
			:gmaps_url,
			:practice_court,
			:season_id,
			seasons: [],
			season_locations: [],
			seasons_attributes: [:id, :_destroy]
		)
	end
end
