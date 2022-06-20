class LocationsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_locations, only: [:index, :show, :edit, :new, :update, :destroy, :locations]

  # GET /locations
  # GET /locations.json
  def index
    if current_user.present? and (current_user.admin? or current_user.is_coach?)
      @season = Season.find(params[:season_id]) if params[:season_id]
      @title  = title_fields(I18n.t(:l_loc_index))
      @title << [@season ? {kind: "label", value: @season.name} : {kind: "search-text", key: :search, value: params[:search], url: locations_path}]
      @grid = location_grid
	else
			redirect_to "/"
		end
  end

  # GET /locations/1
  # GET /locations/1.json
  def show
    if current_user.present? and (current_user.admin? or current_user.is_coach?)
      @fields = title_fields(@location.name)
      @fields << [(@location.gmaps_url and @location.gmaps_url.length > 0) ? {kind: "location", url: @location.gmaps_url, name: I18n.t(:l_loc_see)} : {kind: "text", value: I18n.t(:l_loc_none)}]
      @fields << [{kind: "icon", value: @location.practice_court ? "training.svg" : "team.svg"}]
    else
			redirect_to "/"
    end
  end

  # GET /locations/1/edit
  def edit
    if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@location = Location.new(name: t(:d_loc)) unless @location
      @fields   = form_fields(I18n.t(:l_loc_edit))
		else
			redirect_to "/"
		end
  end

  # GET /locations/new
  def new
    if current_user.present? and (current_user.admin? or current_user.is_coach?)
      @location = Location.new(name: t(:d_loc)) unless @location
      @fields   = form_fields(I18n.t(:l_loc_new))
    else
			redirect_to "/"
		end
  end

  # POST /locations
  # POST /locations.json
  def create
    if current_user.present? and (current_user.admin? or current_user.is_coach?)
	    respond_to do |format|
	      rebuild_location # rebuild @location
        if @location.id!=nil  # @location is already stored in database
          if @season
            @season.locations |= [@location]
            format.html { redirect_to season_locations_path(@season), notice: "#{I18n.t(:loc_created)} #{@season.name} => '#{@location.name}'" }
	          format.json { render :index, status: :created, location: season_locations_path(@season) }
          else
            format.html { render @location, notice: t(:loc_created) + "'#{@location.name}'" }
            format.json { render :show, :created, location: locations_url(@location) }
          end
        else
          if @location.save
            @season.locations |= [@location] if @season
            format.html { redirect_to @season ? season_locations_path(@season) : locations_url, notice: "#{I18n.t(:loc_created)} '#{@location.name}'" }
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
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
      respond_to do |format|
        rebuild_location
        if @location.id!=nil  # we have location to save
          if @location.update(location_params)  # try to save
            @season.locations |= [@location] if @season
            format.html { redirect_to @season ? seasons_path(@season) : locations_path, notice: "#{I18n.t(:loc_updated)} '#{@location.name}'" }
    				format.json { render :index, status: :created, location: locations_path }
          else
            format.html { redirect_to edit_location_path(@location) }
            format.json { render json: @location.errors, status: :unprocessable_entity }
          end
        else
          format.html { render @season ? season_locations_path(@season) : locations_path }
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
      respond_to do |format|
        l_name = @location.name
        if @season
          @season.locations.delete(@location)
          @locations = @season.locations
          format.html { redirect_to season_locations_path(@season), notice: "#{I18n.t(:loc_deleted)} #{@season.name} => '#{l_name}'" }
          format.json { render :index, status: :created, location: season_locations_path(@season) }
        else
          @location.scrub
          @location.delete
          format.html { render @location, notice: "#{I18n.t(:loc_created)} '#{l_name}'" }
          format.json { render :show, :created, location: locations_url(@location) }
        end
      end
    else
      redirect_to "/"
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
    res << [{kind: "icon", value: "training.svg"}, {kind: "label-checkbox", key: :practice_court, label: I18n.t(:l_loc_train)}]
    res.last << {kind: "hidden", key: :season_id, value: @season.id} if @season
    res
  end

  # return grid for @locations GridComponent
  def location_grid
    title = [
      {kind: "normal", value: I18n.t(:h_name)},
      {kind: "normal", value: I18n.t(:h_kind), align: "center"},
      {kind: "normal", value: I18n.t(:a_loc)}
    ]
    title << {kind: "add", url: @season ? season_locations_path(@season)+"/new" : new_location_path, turbo: "modal"} if current_user.admin? or current_user.is_coach?

    rows = Array.new
    @locations.each { |loc|
      row = {url: edit_location_path(loc), turbo: "modal", items: []}
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

  # rebuild @location from params[:location]
  def rebuild_location
    loc    = params[:id] ? Location.find(params[:id]) : Location.new
    l_data = location_params
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

  # Never trust parameters from the scary internet, only allow the white list through.
  def location_params
    params.require(:location).permit(:id, :name, :gmaps_url, :practice_court, seasons: [], season_locations: [] , seasons_attributes: [:id, :_destroy])
  end
end
