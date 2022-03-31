class SlotsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
  before_action :set_slot, only: [:show, :edit, :update, :destroy]


  # GET /slots or /slots.json
  def index
    if current_user.present?
      @season = Season.find(params[:season_id]) if params[:season_id]
      @slots  = Slot.search(params[:season_id], params[:location_id], params[:team_id])
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
		@weekdays = weekdays
    @season   = Season.find(@slot.season_id)
  end

  # POST /slots or /slots.json
  def create
    if current_user.present? and current_user.admin?
      respond_to do |format|
  			rebuild_slot(params)	# rebuild slot
        if @slot.save
          format.html { redirect_to slots_url }
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
  			rebuild_slot(params)
        if @slot.update(slot_params)
        format.html { redirect_to slots_url }
          format.json { render :index, status: :ok, location: @slot }
        else
          format.html { render :edit, status: :unprocessable_entity }
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
      set_slot(params)
      @slot.destroy
      respond_to do |format|
        format.html { redirect_to slots_url }
        format.json { head :no_content }
      end
    else
      redirect_to(current_user.present? ? slots_url : "/")
    end
  end

	# returns an array with weekday names and their id
	def weekdays
		[["Lunes", 1], ["Martes", 2], ["Miércoles", 3], ["Jueves", 4], ["Viernes", 5]]
	end

  private
		# build new @slot from raw input given by submittal from "new"
		# return nil if unsuccessful
		def rebuild_slot(params)
      @slot  = Slot.new(start: Time.new(2021,8,30,17,00))
			p_data = params.fetch(:slot)
      t = Team.find(p_data[:team_id].to_i).season_id
			@slot.season_id   = t ? t : 0
			@slot.location_id = p_data[:location_id]
			@slot.wday        = p_data[:wday]
			@slot.team_id     = p_data[:team_id]
			@slot.hour        = p_data[:hour]
			@slot.min         = p_data[:min]
			@slot.duration    = p_data[:duration]
			@slot
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
