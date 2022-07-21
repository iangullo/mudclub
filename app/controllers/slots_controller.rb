class SlotsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_slot, only: [:show, :edit, :update, :destroy]


  # GET /slots or /slots.json
  def index
    if current_user.present?
      @season = Season.search(params[:season_id])
      @slots  = Slot.search(params)
      @title  = title_fields(I18n.t("slot.many"))
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
      set_slot(params)
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

    # Use callbacks to share common setup or constraints between actions.
    def set_slot
      @slot = Slot.find(params[:id]) unless @slot.try(:id)==params[:id]
    end

    # Only allow a list of trusted parameters through.
    def slot_params
      params.require(:slot).permit(:season_id, :location_id, :team_id, :wday, :start, :duration, :hour, :min)
    end
end
