class LocationsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_locations, only: [:index, :show, :edit, :new, :update, :destroy, :locations]

  # GET /locations
  # GET /locations.json
  def index
    set_locations unless @locations
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
	      @location = rebuild_location
        if @location.id!=nil
           format.html { redirect_to locations_path, notice: 'Ya existía esta ubicación.', action: :index }
           format.json { render :show, :created, location: @location }
        else
          if @location.save
            format.html { redirect_to locations_path, notice: 'Pista añadida.' }
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

  # PATCH/PUT /locations/1
  # PATCH/PUT /locations/1.json
  def update
		if current_user.present? and (current_user.admin? or current_user.is_coach)
      respond_to do |format|
        @location = rebuild_location
        if @location.id!=nil and @location.update(location_params)
          @session.locations << @location if @session
  	      format.html { redirect_to locations_path, notice: "Pista actualizadas.", action: :index }
  				format.json { render :index, status: :created, location: locations_path }
        else
          format.html { redirect_to edit_location_path(@location) }
          format.json { render json: @location.errors, status: :unprocessable_entity }
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
			@location.delete
	    respond_to do |format|
	      format.html { redirect_to locations_path, notice: 'Pista elminada.' }
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
      @locations = Location.real.order(:name)
    end
    if params[:id]
      @location = Location.find(params[:id]) unless @location.try(:id)==params[:id]
    end
  end

  # rebuild @location from params[:location]
  def rebuild_location
    if params[:location]
      loc                = Location.new
      loc.name           = params[:location][:name]
      loc.exists? # reload from database
      loc.gmaps_url      = params[:location][:gmaps_url]
      loc.practice_court = (params[:location][:practice_court] == "1")
      loc
    else
      nil
    end
  end
end
