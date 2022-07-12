class SeasonsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_season, only: [:index, :edit, :update, :destroy, :locations]

  # GET /seasons
  # GET /seasons.json
  def index
    if current_user.present? and current_user.admin?
			@season = Season.search(params[:search])
      @events = Event.upcoming.for_season(@season).non_training
      @title  = title_fields(I18n.t(:l_sea_show), cols: 2)
      @title << [{kind: "search-collection", key: :search, url: seasons_path, options: Season.real.order(start_date: :desc)}, {kind: "add", url: new_season_path, label: I18n.t(:m_create), turbo: "modal"}]
      @links  = [
        [ # season links
          {kind: "jump", icon: "location.svg", url: season_locations_path(@season), label: I18n.t(:l_courts), align: "center"},
          {kind: "jump", icon: "team.svg", url: teams_path + "?season_id=" + @season.id.to_s, label: I18n.t(:l_team_index), align: "center"},
          {kind: "jump", icon: "timetable.svg", url: @season.locations.empty? ? season_slots_path(@season) : season_slots_path(@season, location_id: @season.locations.first.id), label: I18n.t(:l_slot_index), align: "center"},
          {kind: "edit", url: edit_season_path(@season), size: "30x30", turbo: "modal"}
        ]
      ]
      @grid = event_grid(events: @events, obj: @season)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

  # GET /seasons/1/edit
  def edit
    if current_user.present? and current_user.admin?
			@season = Season.new(start_date: Date.today, end_date: Date.today) unless @season
      @eligible_locations = @season.eligible_locations
      @fields = form_fields(I18n.t(:l_sea_edit))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

  # GET /seasons/new
  def new
    if current_user.present? and current_user.admin?
      @season = Season.new(start_date: Date.today, end_date: Date.today)
      @fields = form_fields(I18n.t(:l_sea_new))
    else
			redirect_to "/", data: {turbo_action: "replace"}
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
	        format.html { redirect_to seasons_path(@season), notice: {kind: "success", message: "#{I18n.t(:sea_created)} '#{@season.name}'"}, data: {turbo_action: "replace"} }
	        format.json { render :index, status: :created, location: seasons_url }
	      else
	        format.html { render :new }
	        format.json { render json: @season.errors, status: :unprocessable_entity }
	      end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
    end
  end

  # PATCH/PUT /seasons/1
  # PATCH/PUT /seasons/1.json
  def update
		if current_user.present? and current_user.admin?
    	respond_to do |format|
        check_locations
      	if @season.update(season_params)
	        format.html { redirect_to seasons_path(@season), notice: {kind: "success", message: "#{I18n.t(:sea_updated)} '#{@season.name}'"}, data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: seasons_url}
	      else
	        format.html { render :edit }
	        format.json { render json: @season.errors, status: :unprocessable_entity }
	      end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
    end
  end

  # DELETE /seasons/1
  # DELETE /seasons/1.json
  def destroy
		if current_user.present? and current_user.admin?
      s_name = @season.name
			erase_links
			@season.destroy
	    respond_to do |format|
	      format.html { redirect_to seasons_path, status: :see_other, notice: {kind: "success", message: "#{I18n.t(:sea_deleted)} '#{s_name}'"}, data: {turbo_action: "replace"} }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
  end

  private

    # return icon and top of HeaderComponent
  	def title_fields(title, cols: nil)
      title_start(icon: "calendar.svg", title: title, cols: cols)
  	end

  	# return HeaderComponent @fields for forms
  	def form_fields(title, cols: nil)
      res = title_fields(title, cols: cols)
    	res << [{kind: "subtitle", value: @season.name}]
      res << [{kind: "label", align: "right", value: I18n.t(:h_start)}, {kind: "date-box", key: :start_date, s_year: 2020, value: @season.start_date}]
      res << [{kind: "label", align: "right", value: I18n.t(:h_end)}, {kind: "date-box", key: :end_date, s_year: 2020, value: @season.end_date}]
  		res
  	end

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
