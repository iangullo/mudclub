class LocationsController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_locations, only: [:index, :show, :edit, :new, :update, :destroy, :locations]

	# GET /locations
	# GET /locations.json
	def index
		check_access(roles: [:admin, :coach])
		@season = Season.find(params[:season_id]) if params[:season_id]
		@title  = helpers.location_title_fields(title: I18n.t("location.many"))
		@title << [@season ? {kind: "label", value: @season.name} : {kind: "search-text", key: :search, value: params[:search], url: locations_path}]
		@grid = helpers.location_grid(locations: @locations, season: @season)
	end

	# GET /locations/1
	# GET /locations/1.json
	def show
		check_access(roles: [:user])
		@fields = helpers.location_show_fields(location: @location)
	end

	# GET /locations/1/edit
	def edit
		check_access(roles: [:admin, :coach])
		@location = Location.new(name: I18n.t("location.default")) unless @location
		@fields   = helpers.location_form_fields(title: I18n.t("location.edit"), location: @location, season: @season)
	end

	# GET /locations/new
	def new
		check_access(roles: [:admin, :coach])
		@location = Location.new(name: t("location.default")) unless @location
		@fields   = helpers.location_form_fields(title: I18n.t("location.new"), location: @location, season: @season)
	end

	# POST /locations
	# POST /locations.json
	def create
		check_access(roles: [:admin, :coach])
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
	end

	# PATCH/PUT /locations/1 or /locations/1.json
	def update
		check_access(roles: [:admin, :coach])
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
	end

	# DELETE /locations/1
	# DELETE /locations/1.json
	def destroy
		check_access(roles: [:admin])
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
			@location = Location.find(params[:id]) unless @location.try(:id)==params[:id]
		end
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def location_params
		params.require(:location).permit(:id, :name, :gmaps_url, :practice_court, :season_id, seasons: [], season_locations: [] , seasons_attributes: [:id, :_destroy])
	end
end
