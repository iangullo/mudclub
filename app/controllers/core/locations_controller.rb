# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
# Managament of locations registered inmudclub - typicallylinekd to a club
class LocationsController < ApplicationController
	before_action :set_locations, only: [ :index, :show, :edit, :new, :update, :destroy ]

	# GET /club/x/locations
	# GET /club/x/locations.json
	def index
		@policy = check_policy!(CategoryPolicy, club: @club)

		title  = helpers.location_title(title: I18n.t("location.many"))
		title << helpers.location_search_bar(search_in: crud_return)
		page   = paginate(@locations)	# paginate results
		table  = helpers.location_table(locations: page)
		create_index(title:, table:, page:, retlnk: back_link(default: path_for(@club)))
	end

	# GET /locations/1
	# GET /locations/1.json
	def show
		@policy = check_policy!(CategoryPolicy, club: @club, record: @location)

		@fields = create_fields(helpers.location_show)
		submit  = edit_path_for(@location) if location_editor?
		@submit = create_submit(submit:, frame: :modal)
	end

	# GET /locations/1/edit
	def edit
		@policy = check_policy!(CategoryPolicy, club: @club, record: @location)

		prepare_form("edit")
	end

	# GET /locations/new
	def new
		@policy = check_policy!(CategoryPolicy, club: @club)

		@location = Location.new unless @location
		prepare_form("new")
	end

	# POST /locations
	# POST /locations.json
	def create
		@policy = check_policy!(CategoryPolicy, club: @club)

		respond_to do |format|
			@location = Location.new
			@location.rebuild(location_params) # rebuild @location
			a_desc    = "#{I18n.t("location.created")} #{@club&.nick} => '#{@location.name}'"
			u_notice  = helpers.flash_message(a_desc, "success")
			if @location.id!=nil || @location.save # location existed or saved
				retlnk = crud_return
				@club.locations |= [ @location ] if @club
				register_action(:created, a_desc, url: path_for(@location), modal: true)
				format.html { redirect_to retlnk, notice: u_notice, data: { turbo_action: "replace" } }
				format.json { render :index, status: :created, location: retlnk }
			else
				prepare_form("new")
				format.html { render :new }
				format.json { render json: @location.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /locations/1 or /locations/1.json
	def update
		@policy = check_policy!(CategoryPolicy, club: @club, record: @location)

		respond_to do |format|
			@location.rebuild(location_params)
			retlnk = crud_return
			if @location.id!=nil  # we have location to save
				a_desc = "#{I18n.t("location.updated")} '#{@location.name}'"
				if @location.changed?
					if @location.save  # try to save
						register_action(:updated, a_desc, url: path_for(@location, rdx: 2), modal: true)
						@club.locations |= [ @location ]
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
						format.json { render :index, status: :created, location: retlnk }
					else
						format.html { redirect_to edit_path_for(@location), data: { turbo_action: "replace" } }
						format.json { render json: @location.errors, status: :unprocessable_entity }
					end
				elsif @club&.locations&.exclude?(@location)
					format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
					@club.locations << @location
				else
					format.html { redirect_to retlnk, notice: no_data_notice, data: { turbo_action: "replace" } }
					format.json { render :index, status: :unprocessable_entity, location: retlnk }
				end
			else
				prepare_form(title: I18n.t("location.edit"))
				format.html { render retlnk }
				format.json { render :index, status: :unprocessable_entity, location: retlnk }
			end
		end
	end

	# DELETE /locations/1
	# DELETE /locations/1.json
	def destroy
		@policy = check_policy!(CategoryPolicy, club: @club, record: @location)

		respond_to do |format|
			l_name = @location.name
			a_desc = "#{I18n.t("location.deleted")} #{@club&.nick} => '#{l_name}'"
			retlnk = crud_return
			register_action(:deleted, a_desc)
			@club.locations.delete(@location)
			format.html { redirect_to retlnk, status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
			format.json { render :index, status: :created, location: retlnk }
		end
	end

private
	# wrapper to set return link for CRUD operations
	def crud_return(club = @club)
		club_locations_path(club, rdx: @rdx)
	end

	# prepare ViewComponents for a Location edit/new form
	def prepare_form(action)
		@fields = create_fields(helpers.location_form(title: I18n.t("location.#{action}")))
		@submit = create_submit
	end

	# ensure internal variables are well defined
	def set_locations
		club_id = @club&.id || p_clubid
		@club   = Club.find_by_id(club_id)
		if params[:id].present?
			@location = Location.find_by_id(params[:id]) unless @location&.id==params[:id]
		end
		@locations = Location.search(club_id: @club.id, name: params[:name].presence).order(:name)
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def location_params
		params.require(:location).permit(
			:id,
			:club_id,
			:name,
			:gmaps_url,
			:practice_court,
			:rdx
		)
	end
end
