class CoachesController < ApplicationController
  before_action :set_coach, only: %i[ show edit update destroy ]

  # GET /coaches or /coaches.json
  def index
    @coaches = Coach.all
  end

  # GET /coaches/1 or /coaches/1.json
  def show
  end

  # GET /coaches/new
  def new
    @coach = Coach.new
  end

  # GET /coaches/1/edit
  def edit
  end

  # POST /coaches or /coaches.json
  def create
    @coach = Coach.new(coach_params)

    respond_to do |format|
      if @coach.save
        format.html { redirect_to @coach, notice: "Coach was successfully created." }
        format.json { render :show, status: :created, location: @coach }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @coach.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /coaches/1 or /coaches/1.json
  def update
    respond_to do |format|
      if @coach.update(coach_params)
        format.html { redirect_to @coach, notice: "Coach was successfully updated." }
        format.json { render :show, status: :ok, location: @coach }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @coach.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /coaches/1 or /coaches/1.json
  def destroy
    @coach.destroy
    respond_to do |format|
      format.html { redirect_to coaches_url, notice: "Coach was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_coach
      @coach = Coach.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def coach_params
      params.require(:coach).permit(:active, :person_id)
    end
end
