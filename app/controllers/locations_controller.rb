class LocationsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_location, only: [:index, :edit, :update, :destroy, :locations]

  # GET /locations
  # GET /locations.json
  def index
    if current_user.present? and current_user.admin?
      @season = Season.search(params[:season_id])
		else
			redirect_to "/"
		end
  end

  # GET /locations/1/edit
  def edit
    if current_user.present? and current_user.admin?
			@location = location.new(name: "NUEVA") unless @location
		else
			redirect_to "/"
		end
  end

  # GET /locations/new
  def new
    if current_user.present? and current_user.admin?
      @location = location.new(name: "NUEVA")
    else
			redirect_to "/"
		end
  end

  # POST /locations
  # POST /locations.json
  def create
    if current_user.present? and current_user.admin?
    	@location = location.new(location_params)

			# added to import excel
	    respond_to do |format|
	      if @location.save
	        format.html { redirect_to locations_url, notice: 'Temporada creada.' }
	        format.json { render :index, status: :created, location: locations_url }
	      else
	        format.html { render :new }
	        format.json { render json: @location.errors, status: :unprocessable_entity }
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
      	if @location.update(location_params)
	        format.html { redirect_to locations_url, notice: "Temporada actualizada." }
					format.json { render :index, status: :created, location: locations_url }
	      else
	        format.html { render :edit }
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
			erase_links
			@location.destroy
	    respond_to do |format|
	      format.html { redirect_to locations_url, notice: 'Temporada borrada.' }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/"
		end
  end

private
  # Never trust parameters from the scary internet, only allow the white list through.
  def location_params
    params.require(:location).permit(:id, :name, :start, :end, locations: [], location_locations: [])
  end

  def set_location
     @location = location.find(params[:id]) unless @location.try(:id)==params[:id]
  end
end
