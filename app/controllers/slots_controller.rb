class SlotsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_slot, only: [:show, :edit, :update, :destroy]


  # GET /slots or /slots.json
  def index
    if current_user.present?
      @season    = Season.search(params[:season_id])
      @location  = params[:location_id] ? Location.find(params[:location_id]) : @season.locations.practice.first
      @title     = title_fields(I18n.t("slot.many"))
     week_view if @season and @location
    else
      redirect_to "/", data: {turbo_action: "replace"}
    end
  end

  # GET /slots/1 or /slots/1.json
  def show
    unless current_user.present?
      redirect_to "/", data: {turbo_action: "replace"}
    end
    @season = Season.find(params[:season_id]) if params[:season_id]
    @title  = title_fields(I18n.t("slot.many"))
  end

  # GET /slots/new
  def new
    if current_user.present? and current_user.admin?
      @weekdays = weekdays
      @season   = Season.find(params[:season_id]) if params[:season_id]
      @slot     = Slot.new(season_id: @season ? @season.id : 1, location_id: 1, wday: 1, start: Time.new(2021,8,30,17,00), duration: 90, team_id: 0)
      @fields   = form_fields(I18n.t("slot.new"))
    else
      redirect_to(current_user.present? ? slots_url : "/", data: {turbo_action: "replace"})
    end
  end

  # GET /slots/1/edit
  def edit
    if current_user.present? and current_user.admin?
  		@weekdays = weekdays
      @season   = Season.find(@slot.season_id)
      @fields   = form_fields(I18n.t("slot.edit"))
    else
      redirect_to(current_user.present? ? slots_url : "/", data: {turbo_action: "replace"})
    end
  end

  # POST /slots or /slots.json
  def create
    if current_user.present? and current_user.admin?
      respond_to do |format|
  			rebuild_slot	# rebuild @slot
        if @slot.save # try to store
          format.html { redirect_to @season ? season_slots_path(@season, location_id: @slot.location_id) : slots_url, notice: {kind: "success", message: "#{I18n.t("slot.created")} '#{@sot.to_s}'"}, data: {turbo_action: "replace"} }
          format.json { render :index, status: :created, location: @slot }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @slot.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to(current_user.present? ? slots_url : "/", data: {turbo_action: "replace"})
    end
  end

  # PATCH/PUT /slots/1 or /slots/1.json
  def update
    if current_user.present? and current_user.admin?
      respond_to do |format|
  			rebuild_slot
        if @slot.update(slot_params)
          format.html { redirect_to @season ? season_slots_path(@season, location_id: @slot.location_id) : slots_url, notice: {kind: "success", message: "#{I18n.t("slot.updated")} '#{@slot.to_s}'"}, data: {turbo_action: "replace"} }
          format.json { render :index, status: :ok, location: @slot }
        else
          format.html { redirect_to edit_slot_path(@slot) }
          format.json { render json: @slot.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to(current_user.present? ? slots_url : "/", data: {turbo_action: "replace"})
    end
  end

  # DELETE /slots/1 or /slots/1.json
  def destroy
    if current_user.present? and current_user.admin?
      s_name = @slot.to_s
      @slot.destroy
      respond_to do |format|
        format.html { redirect_to @season ? season_slots_path(@season, location_id: @slot.location_id) : slots_url, status: :see_other, notice: {kind: "success", message: "#{I18n.t("slot.deleted")} '#{s_name}'"}, data: {turbo_action: "replace"} }
        format.json { head :no_content }
      end
    else
      redirect_to(current_user.present? ? slots_url : "/")
    end
  end

	# returns an array with weekday names and their id
	def weekdays
    res =[]
    1.upto(5) {|i| res << [I18n.t("calendar.daynames")[i], i]}
    res
	end

  private

    # return icon and top of FieldsComponent
    def title_fields(title)
      res = title_start(icon: "timetable.svg", title: title)
      res << [{kind: "subtitle", value: @season ? @season.name : ""}]
      res
    end

    # return FieldsComponent @fields for forms
    def form_fields(title)
      res = title_fields(title)
      res << [{kind: "icon", value: "team.svg"}, {kind: "select-collection", key: :team_id, options: @season ? Team.for_season(@season.id) : Team.real, value: @slot.team_id, cols: 2}]
      res << [{kind: "icon", value: "location.svg"}, {kind: "select-collection", key: :location_id, options: @season ? @season.locations.practice.order(name: :asc) : Location.practice, value: @slot.location_id, cols: 2}]
      res << [{kind: "icon", value: "calendar.svg"}, {kind: "select-box", key: :wday, options: @weekdays}, {kind: "time-box", hour: @slot.hour, min: @slot.min}]
      res << [{kind: "icon", value: "clock.svg"}, {kind: "number-box", key: :duration, min:60, max: 120, step: 15, value: @slot.duration, units: I18n.t("calendar.mins")}]
      res.last << {kind: "hidden", key: :season_id, value: @season.id} if @season
      res
    end

		# build new @slot from raw input given by submittal from "new" or "edit"
		# always returns a @slot
		def rebuild_slot
      s_data = params.fetch(:slot)
      tslot  = params[:id] ? Slot.find(params[:id]) : Slot.fetch(s_data)
      tslot  = Slot.new(start: Time.new(2021,8,30,17,00)) unless tslot
      tslot.wday        = s_data[:wday]
      tslot.hour        = s_data[:hour]
      tslot.min         = s_data[:min]
      tslot.duration    = s_data[:duration]
      tslot.location_id = s_data[:location_id]
      tslot.team_id     = s_data[:team_id]
      tslot.season_id   = tslot.team.season_id.to_i
      @season = Season.find(s_data[:season_id]) if s_data[:season_id]
			@slot   = tslot
		end

    # create the timetable view grid
    # requires that @location & @season defined
    def week_view
      @w_slots = Slot.search({season_id: @season.id, location_id: @location.id})
      @slices  = create_slices # each slice is a hash {time:, label:, chunks:} Chunks are <td>
      @d_cols  = [1]  # day columns
      1.upto(5) { |i| # fill in data for each day
        d_col   = {name: I18n.t("calendar.daynames_a")[i], cols: day_cols(@season.id, @location.id, i)}
        d_slots = wday_slots(@w_slots, i) # check only daily slots
        @slices.each { |slice| # create slice chunks for this day
          train   = nil # placeholder chunks
          gap     = nil
          time_slots(d_slots, slice[:time]).each { |t_slot| # slots starting on this slice
            t_cols = t_slot.timecols(d_col[:cols], w_slots: d_slots)
            t_rows = t_slot.timerows(i, slice[:time])
            train  = {slot: t_slot, rows: t_rows, cols: t_cols}
            if t_cols < d_col[:cols]  # prepare "gap" if needed
              gap = create_gap(slice[:time], d_col[:cols], d_slots, t_slot, t_cols)
            end
          }
          if train  # a training slot start in this slice
            slice[:chunks] << train 
            slice[:chunks] << gap if gap  # insert gap if required
          else  # is it empty?
            slice[:chunks] << {rows: 1, cols: 1}
          end
        }
        @d_cols << d_col
      }
    end

    # CALCULATE HOW MANY cols we need to reserve for this day
    # i.e. overlapping teams in same location/time
    def day_cols(sea_id, loc_id, wday)
      res     = 1
      s_time  = Time.new(2021,9,1,16,0)
      e_time  = Time.new(2021,9,1,22,30)
      t_time  = s_time
      d_slots = wday_slots(@w_slots, wday)
      while t_time < e_time do	# check the full day
        s_count = 0
        d_slots.each { |slot|
          s_count = s_count+1 if slot.at_work?(wday, t_time)
        }
        res     = s_count if s_count > res
        t_time  = t_time + 15.minutes
      end
      res
    end

    # filter activerecord dataset by wday and return array
    def wday_slots(slots, wday)
      slots.select {|slot| slot.wday==wday}
    end

    # filter activerecord dataset by wday and return array
    def time_slots(slots, start_time)
      slots.select {|slot| slot.start==start_time}
    end

    # Create fresh time_table slices for each timetable row
    def create_slices
      slices  = []
      t_start = Time.utc(2000,1,1,16,00)
      t_end   = Time.utc(2000,1,1,22,30)
      t_hour  = t_start # reset clock
      while t_hour < t_end  # cicle the full day
        slices << {time: t_hour, label: t_hour.min==0 ? (t_hour.hour.to_s.rjust(2,"0") + ":00") : nil, chunks: []}
        t_hour = t_hour + 15.minutes  # 15 min intervals
      end
      slices
    end

    # Create associated gap if needed
    # if t_slot is passed, it needs to be starting at s_time
    def create_gap(s_time, d_cols, d_slots, t_slot=nil, t_cols=0)
      gap     =  nil  # no gap yet
      overlap = false # no overlap detected yet
      t_time  = s_time
      s_end   = t_slot ? t_slot.ending : s_time + 1.minute
      t_slots = t_slot ? d_slots.excluding(t_slot) : d_slots
      if t_slot # if a t_slot given starts at this time
        t_slots.each { |tmp| # seek overlaps
          if tmp.at_work?(tmp.wday, s_time)
            overlap=true 
            break
          end
        }
      end
      unless overlap  # we will need a gap
        gap = {gap: true, rows: 0, cols: d_cols-t_cols}
        while t_time < s_end  # check gap size
          t_slots.each { |tmp| # seek overlaps
            if tmp.at_work?(tmp.wday, t_time)
              overlap=true
              break
            end
          }
          unless overlap
            gap[:rows] = gap[:rows] +1 # need to create a new gap
          else
            break
          end
          t_time = t_time + 15.minutes
        end
      end
      gap
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_slot
      @slot = Slot.find(params[:id]) unless @slot.try(:id)==params[:id]
    end

    # Only allow a list of trusted parameters through.
    def slot_params
      params.require(:slot).permit(:season_id, :location_id, :team_id, :wday, :start, :duration, :hour, :min)
    end
end
