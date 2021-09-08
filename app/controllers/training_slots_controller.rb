class TrainingSlotsController < ApplicationController
  before_action :set_training_slot, only: %i[ show edit update destroy ]

  # GET /training_slots or /training_slots.json
  def index
    @training_slots = TrainingSlot.all
  end

  # GET /training_slots/1 or /training_slots/1.json
  def show
  end

  # GET /training_slots/new
  def new
    @training_slot = TrainingSlot.new
  end

  # GET /training_slots/1/edit
  def edit
  end

  # POST /training_slots or /training_slots.json
  def create
    @training_slot = TrainingSlot.new(training_slot_params)

    respond_to do |format|
      if @training_slot.save
        format.html { redirect_to @training_slot, notice: "Training slot was successfully created." }
        format.json { render :show, status: :created, location: @training_slot }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @training_slot.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /training_slots/1 or /training_slots/1.json
  def update
    respond_to do |format|
      if @training_slot.update(training_slot_params)
        format.html { redirect_to @training_slot, notice: "Training slot was successfully updated." }
        format.json { render :show, status: :ok, location: @training_slot }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @training_slot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /training_slots/1 or /training_slots/1.json
  def destroy
    @training_slot.destroy
    respond_to do |format|
      format.html { redirect_to training_slots_url, notice: "Training slot was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_training_slot
      @training_slot = TrainingSlot.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def training_slot_params
      params.require(:training_slot).permit(:season_id, :location_id, :wday, :start, :duration, :team_id)
    end
end
