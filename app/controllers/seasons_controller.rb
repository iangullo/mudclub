class SeasonsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_season, only: [:index, :edit, :update, :destroy, :locations]

  # GET /seasons
  # GET /seasons.json
  def index
		check_access(roles: [:admin])
		@season = Season.search(params[:search])
    @events = Event.upcoming.for_season(@season).non_training
    @title  = helpers.season_title_fields(title: I18n.t("season.single"), cols: 2)
    @title << [{kind: "search-collection", key: :search, url: seasons_path, options: Season.real.order(start_date: :desc)}, {kind: "add", url: new_season_path, label: I18n.t("action.create"), frame: "modal"}]
    @links  = helpers.season_links(season: @season)
    @grid   = helpers.event_grid(events: @events, obj: @season, retlnk: seasons_path)
  end

  # GET /seasons/1/edit
  def edit
		check_access(roles: [:admin])
		@season = Season.new(start_date: Date.today, end_date: Date.today) unless @season
    @eligible_locations = @season.eligible_locations
    @fields = helpers.season_form_fields(title: I18n.t("season.edit"), season: @season)
  end

  # GET /seasons/new
  def new
		check_access(roles: [:admin])
    @season = Season.new(start_date: Date.today, end_date: Date.today)
    @fields = helpers.season_form_fields(title: I18n.t("season.new"), season: @season)
  end

  # POST /seasons
  # POST /seasons.json
  def create
		check_access(roles: [:admin])
    @season = Season.new(season_params)
    @eligible_locations = @season.eligible_locations
		respond_to do |format|
	    if @season.save
	      format.html { redirect_to seasons_path(@season), notice: {kind: "success", message: "#{I18n.t("season.created")} '#{@season.name}'"}, data: {turbo_action: "replace"} }
	      format.json { render :index, status: :created, location: seasons_url }
	    else
	      format.html { render :new }
	      format.json { render json: @season.errors, status: :unprocessable_entity }
	    end
		end
  end

  # PATCH/PUT /seasons/1
  # PATCH/PUT /seasons/1.json
  def update
		check_access(roles: [:admin])
    respond_to do |format|
      check_locations
    	if @season.update(season_params)
	      format.html { redirect_to seasons_path(@season), notice: {kind: "success", message: "#{I18n.t("season.updated")} '#{@season.name}'"}, data: {turbo_action: "replace"} }
		  	format.json { render :index, status: :created, location: seasons_url}
	    else
	      format.html { render :edit }
	      format.json { render json: @season.errors, status: :unprocessable_entity }
	    end
		end
  end

  # DELETE /seasons/1
  # DELETE /seasons/1.json
  def destroy
		check_access(roles: [:admin])
    s_name = @season.name
		erase_links
		@season.destroy
    respond_to do |format|
      format.html { redirect_to seasons_path, status: :see_other, notice: {kind: "success", message: "#{I18n.t("season.deleted")} '#{s_name}'"}, data: {turbo_action: "replace"} }
      format.json { head :no_content }
    end
  end

  private
    def check_locations
      if params[:season][:locations_attributes]
        params[:season][:locations_attributes].each { |loc|
          if loc[1][:_destroy] == "1"
            @season.locations.delete(loc[1][:id].to_i)
          else
            l = Location.find(loc[1][:id].to_i)
            @season.locations ? @season.locations << l : @season.locations |= l
          end
        }
      end
    end

    def set_season
       @season = Season.find(params[:id]) unless @season.try(:id)==params[:id]
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def season_params
      params.require(:season).permit(:id, :start_date, :end_date, locations_attributes: [:id, :_destroy], locations: [], season_locations: [])
    end
end
