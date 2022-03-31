class SeasonsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_season, only: [:index, :edit, :update, :destroy, :locations]

  # GET /seasons
  # GET /seasons.json
  def index
    if current_user.present? and current_user.admin?
			@season = Season.search(params[:search])
		else
			redirect_to "/"
		end
  end

  # GET /seasons/1/edit
  def edit
    if current_user.present? and current_user.admin?
			@season = Season.new(name: "NUEVA") unless @season
      @eligible_locations = @season.eligible_locations
		else
			redirect_to "/"
		end
  end

  # GET /seasons/new
  def new
    if current_user.present? and current_user.admin?
      @season = Season.new(name: "NUEVA")
    else
			redirect_to "/"
		end
  end

  # POST /seasons
  # POST /seasons.json
  def create
    if current_user.present? and current_user.admin?
    	@season = Season.new(season_params)
      @eligible_locations = @season.eligible_locations

			# added to import excel
	    respond_to do |format|
	      if @season.save
	        format.html { redirect_to seasons_path(@season), action: :index }
	        format.json { render :index, status: :created, location: seasons_url }
	      else
	        format.html { render :new }
	        format.json { render json: @season.errors, status: :unprocessable_entity }
	      end
			end
		else
			redirect_to "/"
    end
  end

  # PATCH/PUT /seasons/1
  # PATCH/PUT /seasons/1.json
  def update
		if current_user.present? and current_user.admin?
    	respond_to do |format|
        check_locations
      	if @season.update(season_params)
	        format.html { redirect_to seasons_path(@season), action: :index }
					format.json { render :index, status: :created, location: seasons_url }
	      else
	        format.html { render :edit }
	        format.json { render json: @season.errors, status: :unprocessable_entity }
	      end
			end
		else
			redirect_to "/"
    end
  end

  # DELETE /seasons/1
  # DELETE /seasons/1.json
  def destroy
		if current_user.present? and current_user.admin?
			erase_links
			@season.destroy
	    respond_to do |format|
	      format.html { redirect_to seasons_path, action: :index }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/"
		end
  end

private
  # Never trust parameters from the scary internet, only allow the white list through.
  def season_params
    params.require(:season).permit(:id, :name, :start, :end, locations_attributes: [:id, :_destroy], locations: [], season_locations: [])
  end

  def set_season
     @season = Season.find(params[:id]) unless @season.try(:id)==params[:id]
  end

  def check_locations
    if params[:season][:locations_attributes]
      params[:season][:locations_attributes].each { |loc|
        if loc[1][:_destroy] == "1"
          @season.locations.delete(loc[1][:id].to_i)
        else
          @season.locations |= [Location.find(loc[1][:id].to_i)]
        end
      }
    end
  end
end
