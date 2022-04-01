class LocationsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_locations, only: [:index, :show, :edit, :new, :update, :destroy, :locations]

  # GET /locations
  # GET /locations.json
  def index
    if current_user.present? and (current_user.admin? or current_user.is_coach)
		else
			redirect_to "/"
		end
  end

  # GET /locations/1
  # GET /locations/1.json
  def show
    if current_user.present? and (current_user.admin? or current_user.is_coach)
    else
			redirect_to "/"
    end
  end

  # GET /locations/1/edit
  def edit
    if current_user.present? and (current_user.admin? or current_user.is_coach)
			@location = Location.new(name: "NUEVA") unless @location
		else
			redirect_to "/"
		end
  end

  # GET /locations/new
  def new
    if current_user.present? and (current_user.admin? or current_user.is_coach)
      @location = Location.new(name: "NUEVA") unless @location
    else
			redirect_to "/"
		end
  end

  # POST /locations
  # POST /locations.json
  def create
    if current_user.present? and (current_user.admin? or current_user.is_coach)
	    respond_to do |format|
	      rebuild_location # rebuild @location
        if @location.id!=nil  # @location is already stored in database
          if @season
            @season.locations |= [@location]
            format.html { redirect_to season_locations_path(@season), action: :index }
            format.json { render :show, :created, location: @location }
          else
            format.html { redirect_to locations_path(@location), action: :index }
            format.json { render :show, :created, location: @location }
          end
        else
          if @location.save
            @season.locations |= [@location] if @season
            format.html { redirect_to locations_path }
	          format.json { render :index, status: :created, location: locations_url }
          else
            format.html { render :new }
            format.json { render json: @location.errors, status: :unprocessable_entity }
          end
			  end
      end
    else
			redirect_to "/"
    end
  end

  # PATCH/PUT /locations/1 or /locations/1.json
  def update
		if current_user.present? and (current_user.admin? or current_user.is_coach)
      respond_to do |format|
        rebuild_location
        if @location.id!=nil  # we have location to save
          if @location.update(location_params)  # try to save
            @season.locations |= [@location] if @season
            format.html { redirect_to @season ? season_locations_path(@season) : locations_path, action: :index }
    				format.json { render :index, status: :created, location: locations_path }
          else
            format.html { render edit_location_path(@location) }
            format.json { render json: @location.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to @season ? season_locations_path(@season) : locations_path, action: :index }
          format.json { render :index, status: :unprocessable_entity, location: locations_path }
        end
      end
    else
      redirect_to "/"
    end
  end

  # DELETE /locations/1
  # DELETE /locations/1.json
  def destroy
		if current_user.present? and current_user.admin?
      @location.scrub
      @location.delete
	    respond_to do |format|
	      format.html { render @season ? season_locations_path(@season) : locations_path, action: :index }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/"
		end
  end

private
  # Never trust parameters from the scary internet, only allow the white list through.
  def location_params
    params.require(:location).permit(:id, :name, :gmaps_url, :practice_court, seasons: [], season_locations: [] , seasons_attributes: [:id, :_destroy])
  end

  # ensure internal variables are well defined
  def set_locations
    if params[:season_id]
      @season = Season.find(params[:season_id]) unless @season.try(:id)==params[:season_id]
      @locations = @season.locations.order(:name)
      @eligible_locations = @season.eligible_locations
    else
      @locations = Location.search(params[:search]).order(:name)
    end
    if params[:id]
      @location = Location.find(params[:id]) unless @location.try(:id)==params[:id]
    end
  end

  # rebuild @location from params[:location]
  def rebuild_location
    loc    = params[:id] ? Location.find(params[:id]) : Location.new
    l_data = params[:location]
    if l_data
      loc.name           = l_data[:name]
      loc.exists? # reload from database
      loc.gmaps_url      = l_data[:gmaps_url] if l_data[:gmaps_url].length > 0
      loc.practice_court = (l_data[:practice_court] == "1")
      @season   = Season.find(l_data[:season_id]) if l_data[:season_id]
    else
      loc = nil
    end
    @location = loc
  end
end
