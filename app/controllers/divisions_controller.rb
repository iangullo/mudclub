class DivisionsController < ApplicationController
  before_action :set_division, only: %i[ show edit update destroy ]

  # GET /divisions or /divisions.json
  def index
    if current_user.present? and current_user.admin?
      @divisions = Division.real
    else
      redirect_to "/"
    end
  end

  # GET /divisions/1 or /divisions/1.json
  def show
    redirect_to "/" unless current_user.present? and current_user.admin?
  end

  # GET /divisions/new
  def new
    if current_user.present? and current_user.admin?
      @division = Division.new
    else
      redirect_to "/"
    end
  end

  # GET /divisions/1/edit
  def edit
    redirect_to "/" unless current_user.present? and current_user.admin?
  end

  # POST /divisions or /divisions.json
  def create
    if current_user.present? and current_user.admin?
      @division = Division.new(division_params)

      respond_to do |format|
        if @division.save
          format.html { redirect_to divisions_url, notice: t(:div_created) + "'#{@division.name}'" }
          format.json { render :index, status: :created, location: divisions_url }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @division.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to "/"
    end
  end

  # PATCH/PUT /divisions/1 or /divisions/1.json
  def update
    if current_user.present? and current_user.admin?
      respond_to do |format|
        if @division.update(division_params)
          format.html { redirect_to divisions_url, notice: t(:div_updated) + "'#{@division.name}'" }
          format.json { render :index, status: :created, location: divisions_url }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @division.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to "/"
    end
  end

  # DELETE /divisions/1 or /divisions/1.json
  def destroy
    if current_user.present? and current_user.admin?
      d_name = @division.name
      prune_teams
      @division.destroy
      respond_to do |format|
        format.html { redirect_to divisions_url, notice: t(:div_deleted) + "'#{d_name}'" }
        format.json { head :no_content }
      end
    else
      redirect_to "/"
    end
  end

  private
    # prune teams from a category to be deleted
    def prune_teams
      @division.teams.each { |t|
        t.category=Division.find(0)  # de-allocate teams
        t.save
      }
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_division
      @division = Division.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def division_params
      params.require(:division).permit(:name)
    end
end
