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
class LocationsController < ApplicationController
	before_action :set_locations, only: [:index, :show, :edit, :new, :update, :destroy, :locations]

	# GET /club/x/locations
	# GET /club/x/locations.json
	def index
		if check_access(roles: [:admin, :manager])
			title  = helpers.location_title_fields(title: I18n.t("location.many"))
			title << helpers.location_search_bar(search_in: club_locations_path)
			page   = paginate(@locations)	# paginate results
			grid   = helpers.location_grid(locations: page)
			create_index(title:, grid:, page:, retlnk: club_path(@club))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /locations/1
	# GET /locations/1.json
	def show
		if user_signed_in?	# basically all users can see this
			@fields = create_fields(helpers.location_show_fields)
			@submit = create_submit(submit: nil, frame: "modal")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /locations/1/edit
	def edit
		if check_access(obj: Club.find_by_id(@clubid))
			prepare_form(title: I18n.t("location.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /locations/new
	def new
		if check_access(obj: Club.find_by_id(@clubid))
			@location = Location.new unless @location
			prepare_form(title: I18n.t("location.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /locations
	# POST /locations.json
	def create
		@club = Club.find_by_id(@clubid)
		if check_access(obj: @club)
			respond_to do |format|
				@location = Location.new
				@location.rebuild(location_params) # rebuild @location
				a_desc    = "#{I18n.t("location.created")} #{@club&.nick} => '#{@location.name}'"
				u_notice  = helpers.flash_message(a_desc, "success")
				retlnk    = club_locations_path(@club)
				if @location.id!=nil || @location.save # location existed or saved
					@club.locations |= [@location] if @club
					register_action(:created, a_desc, url: location_path(@location), modal: true)
					format.html { redirect_to retlnk, notice: u_notice, data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: retlnk }
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
		@club = Club.find_by_id(@clubid)
		if check_access(obj: @club)
			respond_to do |format|
				@location.rebuild(location_params)
				retlnk = club_locations_path(@clubid)
				if @location.id!=nil  # we have location to save
					a_desc = "#{I18n.t("location.updated")} '#{@location.name}'"
					if @location.changed?
						if @location.save  # try to save
							register_action(:updated, a_desc, url: location_path(@location, rdx: 2), modal: true)
							@club.locations |= [@location]
							format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
							format.json { render :index, status: :created, location: retlnk }
						else
							format.html { redirect_to edit_location_path(@location), data: {turbo_action: "replace"} }
							format.json { render json: @location.errors, status: :unprocessable_entity }
						end
					elsif @club&.locations&.exclude?(@location)
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						@club.locations << @location
					else
						format.html { redirect_to retlnk, notice: no_data_notice, data: {turbo_action: "replace"} }
						format.json { render :index, status: :unprocessable_entity, location: retlnk }
					end
				else
					prepare_form(title: I18n.t("location.edit"))
					format.html { render retlnk }
					format.json { render :index, status: :unprocessable_entity, location: retlnk }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /locations/1
	# DELETE /locations/1.json
	def destroy
		@club = Club.find_by_id(@clubid)
		if check_access(obj: @club)
			respond_to do |format|
				l_name = @location.name
				a_desc = "#{I18n.t("location.deleted")} #{@club&.nick} => '#{l_name}'"
				retlnk = club_locations_path(@clubid)
				register_action(:deleted, a_desc)
				@club.locations.delete(@location)
				format.html { redirect_to retlnk, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { render :index, status: :created, location: retlnk }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

private
	# ensure internal variables are well defined
	def set_locations
		club_id = @clubid || @club&.id || p_clubid
		@club   = Club.find_by_id(club_id)
		@clubid = @club&.id
		if params[:id].present?
			@location = Location.find_by_id(params[:id]) unless @location&.id==params[:id]
		end
		@locations = Location.search(club_id: @clubid, name: params[:name].presence).order(:name)
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
			:club_id,
			:name,
			:gmaps_url,
			:practice_court
		)
	end
end
