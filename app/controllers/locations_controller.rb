class LocationsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_locations, only: [:index, :show, :edit, :new, :update, :destroy, :locations]

  # GET /locations
  # GET /locations.json
  def index
    check_access(roles: [:admin, :coach])
    @season = Season.find(params[:season_id]) if params[:season_id]
    @title  = title_fields(I18n.t("location.many"))
    @title << [@season ? {kind: "label", value: @season.name} : {kind: "search-text", key: :search, value: params[:search], url: locations_path}]
    @grid = location_grid
  end

  # GET /locations/1
  # GET /locations/1.json
  def show
    check_access(roles: [:user])
    @fields = title_fields(@location.name)
    @fields << [(@location.gmaps_url and @location.gmaps_url.length > 0) ? {kind: "location", url: @location.gmaps_url, name: I18n.t("location.see")} : {kind: "text", value: I18n.t("location.none")}]
    @fields << [{kind: "icon", value: @location.practice_court ? "training.svg" : "team.svg"}]
  end

  # GET /locations/1/edit
  def edit
    check_access(roles: [:admin, :coach])
  	@location = Location.new(name: I18n.t("location.default")) unless @location
    @fields   = form_fields(I18n.t("location.edit"))
  end

  # GET /locations/new
  def new
    check_access(roles: [:admin, :coach])
    @location = Location.new(name: t("location.default")) unless @location
    @fields   = form_fields(I18n.t("location.new"))
  end

  # POST /locations
  # POST /locations.json
  def create
    check_access(roles: [:admin, :coach])
    respond_to do |format|
      @location = Location.new
      @location.rebuild(location_params) # rebuild @location
      if @location.id!=nil  # @location is already stored in database
        if @season
          @season.locations |= [@location]
          format.html { redirect_to season_locations_path(@season), notice: {kind: "info", message: "#{I18n.t("location.created")} #{@season.name} => '#{@location.name}'"}, data: {turbo_action: "replace"} }
	        format.json { render :index, status: :created, location: season_locations_path(@season) }
        else
          format.html { render @location, notice: {kind: "info", message: t(:loc_created) + "'#{@location.name}'"}}
          format.json { render :show, :created, location: locations_url(@location) }
        end
      else
        if @location.save
          @season.locations |= [@location] if @season
          format.html { redirect_to @season ? season_locations_path(@season) : locations_url, notice: {kind: "success", message: "#{I18n.t("location.created")} '#{@location.name}'"}, data: {turbo_action: "replace"} }
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
          format.html { redirect_to @season ? seasons_path(@season) : locations_path, notice: {kind: "success", message: "#{I18n.t("location.updated")} '#{@location.name}'"}, data: {turbo_action: "replace"} }
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
        format.html { redirect_to season_locations_path(@season), status: :see_other, notice: {kind: "success", message: "#{I18n.t("location.deleted")} #{@season.name} => '#{l_name}'"}, data: {turbo_action: "replace"} }
        format.json { render :index, status: :created, location: season_locations_path(@season) }
      else
        @location.scrub
        @location.delete
        format.html { redirect_to locations_path, status: :see_other, notice: {kind: "success", message: "#{I18n.t("location.deleted")} '#{l_name}'"}}
        format.json { render :show, :created, location: locations_url(@location) }
      end
    end
  end

private

  # return icon and top of FieldsComponent
  def title_fields(title)
    res = title_start(icon: "location.svg", title: title)
  end

  # return FieldsComponent @title for forms
  def form_fields(title)
    res = title_fields(title)
    res << [{kind: "text-box", key: :name, value: @location.name, size: 20}]
    res << [{kind: "icon", value: "gmaps.svg"}, {kind: "text-box", key: :gmaps_url, value: @location.gmaps_url, size: 20}]
    res << [{kind: "icon", value: "training.svg"}, {kind: "label-checkbox", key: :practice_court, label: I18n.t("location.train")}]
    res.last << {kind: "hidden", key: :season_id, value: @season.id} if @season
    res
  end

  # return grid for @locations GridComponent
  def location_grid
    title = [
      {kind: "normal", value: I18n.t("location.name")},
      {kind: "normal", value: I18n.t("kind.single"), align: "center"},
      {kind: "normal", value: I18n.t("location.abbr")}
    ]
    title << {kind: "add", url: @season ? season_locations_path(@season)+"/new" : new_location_path, frame: "modal"} if current_user.admin? or current_user.is_coach?

    rows = Array.new
    @locations.each { |loc|
      row = {url: edit_location_path(loc), frame: "modal", items: []}
      row[:items] << {kind: "normal", value: loc.name}
      row[:items] << {kind: "icon", value: loc.practice_court ? "training.svg" : "team.svg", align: "center"}
      if loc.gmaps_url
        row[:items] << {kind: "location", icon: "gmaps.svg", align: "center", url: loc.gmaps_url}
      else
        row[:items] << {kind: "normal", value: ""}
      end
      row[:items] << {kind: "delete", url: location_path(loc), name: loc.name} if current_user.admin?
      rows << row
    }
    {title: title, rows: rows}
  end

  # ensure internal variables are well defined
  def set_locations
    if params[:season_id]
      @season = Season.find(params[:season_id]) unless @season.try(:id)==params[:season_id]
      @locations = @season.locations.order(:name)
      @eligible_locations = @season.eligible_locations
    else
      @locations = Location.search(params[:search]).order(:name)
      @season    = Season.find(params[:location][:season_id]) if params[:location].try(:season_id)
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
