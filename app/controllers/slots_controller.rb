class SlotsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_slot, only: [:show, :edit, :update, :destroy]


  # GET /slots or /slots.json
  def index
    if current_user.present?
      @season = Season.search(params[:season_id])
      @slots  = Slot.search(params)
      @header = header_fields(I18n.t(:l_slot_index))
    else
      redirect_to "/"
    end
  end

  # GET /slots/1 or /slots/1.json
  def show
    unless current_user.present?
      redirect_to "/"
    end
  end

  # GET /slots/new
  def new
    if current_user.present? and current_user.admin?
      @season = Season.find(params[:season_id]) if params[:season_id]
      @slot   = Slot.new(season_id: @season ? @season.id : 1, location_id: 1, wday: 1, start: Time.new(2021,8,30,17,00), duration: 90, team_id: 0)
  		@weekdays = weekdays
    else
      redirect_to(current_user.present? ? slots_url : "/")
    end
  end

  # GET /slots/1/edit
  def edit
    if current_user.present? and current_user.admin?
  		@weekdays = weekdays
      @season   = Season.find(@slot.season_id)
    else
      redirect_to(current_user.present? ? slots_url : "/")
    end
  end

  # POST /slots or /slots.json
  def create
    if current_user.present? and current_user.admin?
      respond_to do |format|
  			rebuild_slot	# rebuild @slot
        if @slot.save # try to store
          format.html { redirect_to @season ? season_slots_path(@season, location_id: @slot.location_id) : slots_url, notice: t(:slot_created) + "'#{@slot.to_s}'" }
          format.json { render :index, status: :created, location: @slot }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @slot.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to(current_user.present? ? slots_url : "/")
    end
  end

  # PATCH/PUT /slots/1 or /slots/1.json
  def update
    if current_user.present? and current_user.admin?
      respond_to do |format|
  			rebuild_slot
        if @slot.update(slot_params)
          format.html { redirect_to @season ? season_slots_path(@season, location_id: @slot.location_id) : slots_url, notice: t(:slot_updated) + "'#{@slot.to_s}'" }
          format.json { render :index, status: :ok, location: @slot }
        else
          format.html { redirect_to edit_slot_path(@slot) }
          format.json { render json: @slot.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to(current_user.present? ? slots_url : "/")
    end
  end

  # DELETE /slots/1 or /slots/1.json
  def destroy
    if current_user.present? and current_user.admin?
      s_name = @slot.to_s
      set_slot(params)
      @slot.destroy
      respond_to do |format|
        format.html { redirect_to @season ? season_slots_path(@season, location_id: @slot.location_id) : slots_url, notice: t(:slot_deleted) + "'#{s_name}'" }
        format.json { head :no_content }
      end
    else
      redirect_to(current_user.present? ? slots_url : "/")
    end
  end

	# returns an array with weekday names and their id
	def weekdays
		[[t(:l_wday_1), 1], [t(:l_wday_2), 2], [t(:l_wday_3), 3], [t(:l_wday_4), 4], [t(:l_wday_5), 5]]
	end

  private

    # return icon and top of FieldsComponent
    def header_fields(title)
      return [
        [{kind: "header-icon", value: "timetable.svg"}, {kind: "title", value: title}],
        [{kind: "subtitle", value: @season ? @season.name : ""}]
      ]
    end

    # return FieldsComponent @fields for forms
    def form_fields(title, rows: 3, cols: 2)
      res = header_fields(title, icon: @player.picture, rows: rows, cols: cols, size: "100x100", _class: "rounded-full")
      f_cols = cols>2 ? cols - 1 : nil
      res << [{kind: "label", value: I18n.t(:l_name)}, {kind: "text-box", key: :name, value: @player.person.name, cols: f_cols}]
      res << [{kind: "label", value: I18n.t(:l_surname)}, {kind: "text-box", key: :surname, value: @player.person.surname, cols: f_cols}]
      if f_cols	# i's an edit form
        res << [{kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @player.person.birthday, cols: f_cols}]
      end
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
