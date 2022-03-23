class LocationsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_location, only: [:index, :show, :edit, :new, :update, :destroy, :locations]

  # GET /locations
  # GET /locations.json
  def index
    if current_user.present? and current_user.admin?
		else
			redirect_to "/"
		end
  end

  # GET /locations/1/edit
  def edit
    if current_user.present? and current_user.admin?
			@location = Location.new(name: "NUEVA") unless @location
		else
			redirect_to "/"
		end
  end

  # GET /locations/new
  def new
    if current_user.present? and current_user.admin?
      @location = Location.new(name: "NUEVA") unless @location
    else
			redirect_to "/"
		end
  end

  # POST /locations
  # POST /locations.json
  def create
    if current_user.present? and current_user.admin?
	    respond_to do |format|
	      rebuild_location
        if @location.exists?
           format.html { redirect_to @location, notice: 'Ya existía esta ubicación.'}
           format.json { render :show, :created, location: @location }
        else
          if @location.save
            format.html { redirect_to locations_url, notice: 'Pista añadida.' }
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
		if current_user.present? and current_user.admin?
      respond_to do |format|
        rebuild_location
      	if @location.update(location_params)
	        format.html { redirect_to locations_url, notice: "Pistas actualizadas." }
					format.json { render :index, status: :created, location: locations_url }
	      else
	        format.html { redirect_to :edit }
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

	      format.html { redirect_to locations_url, notice: 'Pista elminada.' }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/"
		end
  end

private
  # Never trust parameters from the scary internet, only allow the white list through.
  def location_params
    params.require(:location).permit(:id, :name, :start, :end, seasons: [], season_locations: [])
  end

  def set_location
    if params[:season_id]
      @season = Season.find(params[:season_id]) unless @season.try(:id)==params[:season_id]
      @locations = @season.locations
      @eligible_locations = @season.eligible_locations
    else
      @locations = Location.real
    end
    if params[:id]
      @location = Location.find(params[:id]) unless @location.try(:id)==params[:id]
    end
  end

  def rebuild_location
    if params[:location]
      @location                = Location.new
      @location.name           =  params[:location][:name]
      @location.gmaps_url      =  params[:location][:gmaps_url]
      @location.practice_court = (params[:location][:practice_court] == "1")
    end
  end
end
