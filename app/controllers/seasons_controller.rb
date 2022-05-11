class SeasonsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_season, only: [:index, :edit, :update, :destroy, :locations]

  # GET /seasons
  # GET /seasons.json
  def index
    if current_user.present? and current_user.admin?
			@season        = Season.search(params[:search])
      @events        = Event.upcoming.for_season(@season).non_training
      @header_fields = header_fields(I18n.t(:l_sea_show), cols: 2)
      @header_fields << [{kind: "search-collection", key: :search, url: seasons_path, collection: Season.real.order(name: :desc)}, {kind: "modal-add", url: new_season_path}]
      @link_fields = [[ # season links
        {kind: "jump", icon: "location.svg", url: season_locations_path(@season), label: I18n.t(:l_courts)},
        {kind: "jump", icon: "team.svg", url: teams_path + "?season_id=" + @season.id.to_s, label: I18n.t(:l_team_index)},
        {kind: "jump", icon: "timetable.svg", url: @season.locations.empty? ? season_slots_path(@season) : season_slots_path(@season, location_id: @season.locations.first.id), label: I18n.t(:l_slot_index)},
        {kind: "edit", url: edit_season_path(@season), size: "30x30", modal: true}
      ]]
      @g_head = grid_header
      @g_rows = grid_rows
		else
			redirect_to "/"
		end
  end

  # GET /seasons/1/edit
  def edit
    if current_user.present? and current_user.admin?
			@season = Season.new(name: "NUEVA") unless @season
      @eligible_locations = @season.eligible_locations
      @fields = form_fields(I18n.t(:l_sea_edit))
		else
			redirect_to "/"
		end
  end

  # GET /seasons/new
  def new
    if current_user.present? and current_user.admin?
      @season = Season.new(name: "NUEVA")
      @fields = form_fields(I18n.t(:l_sea_new))
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
	        format.html { redirect_to seasons_path(@season), notice: t(:sea_created) + "'#{@season.name}'" }
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
	        format.html { redirect_to seasons_path(@season), notice: t(:sea_updated) + "'#{@season.name}'" }
					format.json { render :index, status: :created, location: seasons_url, notice: t(:sea_updated) + "'#{@season.name}'" }
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
      s_name = @season.name
			erase_links
			@season.destroy
	    respond_to do |format|
	      format.html { redirect_to seasons_path, notice: t(:sea_deleted) + "'#{s_name}'" }
	      format.json { head :no_content }
	    end
		else
			redirect_to "/"
		end
  end

  private

    # return icon and top of HeaderComponent
  	def header_fields(title, cols: nil)
  	  [[{kind: "header-icon", value: "calendar.svg"}, {kind: "title", value: title, cols: cols}]]
  	end

  	# return HeaderComponent @fields for forms
  	def form_fields(title, cols: nil)
      res = header_fields(title, cols: cols)
    	res << [{kind: "text-box", key: :name, value: @season.name}]
      res << [{kind: "label", align: "right", value: I18n.t(:h_start)}, {kind: "date-box", key: :start_date, s_year: 2020, value: @season.start_date}]
      res << [{kind: "label", align: "right", value: I18n.t(:h_end)}, {kind: "date-box", key: :end_date, s_year: 2020, value: @season.end_date}]
  		res
  	end
    # return header for @categories GridComponent
    def grid_header
      res = [
        {kind: "normal", value: I18n.t(:h_date), align: "center"},
        {kind: "normal", value: I18n.t(:h_time), align: "center"},
        {kind: "normal", value: I18n.t(:l_team_show), align: "center"},
        {kind: "normal", value: I18n.t(:h_opponent), align: "center"}
      ]
      res << {kind: "add", url: new_event_path(event: {kind: :holiday, team_id: 0, season_id: @season.id}), modal: true} if current_user.admin? or current_user.is_coach?
    end

    # return content rows for @categories GridComponent
    def grid_rows
      res = Array.new
      @events.each { |event|
        row = {url:  event_path(event, season_id: @season ? @season.id : nil), modal: true, items: []}
        row[:items] << {kind: "normal", value: event.date_string, align: "center"}
        row[:items] << {kind: "normal", value: event.time_string, align: "center"}
        row[:items] << {kind: "normal", value: event.team_id > 0 ? event.team.to_s : t(:l_all)}
        row[:items] << {kind: "normal", value: event.to_s(true)}
        row[:items] << {kind: "delete", url: row[:url], name: event.to_s} if current_user.admin? or (event.team_id>0 and event.team.has_coach(current_user.person.coach_id))
        res << row
      }
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
      params.require(:season).permit(:id, :name, :start_date, :end_date, locations_attributes: [:id, :_destroy], locations: [], season_locations: [])
    end
end
