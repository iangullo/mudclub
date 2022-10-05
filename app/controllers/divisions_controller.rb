class DivisionsController < ApplicationController
  before_action :set_division, only: %i[ show edit update destroy ]

  # GET /divisions or /divisions.json
  def index
		check_access(roles: [:admin])
    @divisions = Division.real
    @fields    = helpers.division_title_fields(title: I18n.t("division.many"))
    @grid      = helpers.division_grid(divisions: @divisions)
  end

  # GET /divisions/1 or /divisions/1.json
  def show
		check_access(roles: [:admin])
    @fields = helpers.division_title_fields(title: I18n.t("division.single"))
    @fields << [{kind: "subtitle", value: @division.name}]
  end

  # GET /divisions/new
  def new
		check_access(roles: [:admin])
    @division = Division.new
    @fields   = helpers.division_form_fields(title: I18n.t("division.new"), division: @division)
  end

  # GET /divisions/1/edit
  def edit
		check_access(roles: [:admin])
    @fields   = helpers.division_form_fields(title: I18n.t("division.edit"), division: @division)
  end

  # POST /divisions or /divisions.json
  def create
		check_access(roles: [:admin])
    @division = Division.new(division_params)
    respond_to do |format|
      if @division.save
        format.html { redirect_to divisions_url, notice: {kind: "success", message: "#{I18n.t("division.created")} '#{@division.name}'"}, data: {turbo_action: "replace"} }
        format.json { render :index, status: :created, location: divisions_url }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @division.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /divisions/1 or /divisions/1.json
  def update
		check_access(roles: [:admin])
    respond_to do |format|
      if @division.update(division_params)
        format.html { redirect_to divisions_url, notice: {kind: "success", message: "#{I18n.t("division.updated")} '#{@division.name}'"}, data: {turbo_action: "replace"} }
        format.json { render :index, status: :created, location: divisions_url }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @division.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /divisions/1 or /divisions/1.json
  def destroy
		check_access(roles: [:admin])
    d_name = @division.name
    prune_teams
    @division.destroy
    respond_to do |format|
      format.html { redirect_to divisions_url, status: :see_other, notice: {kind: "success", message: "#{I18n.t("division.deleted")} '#{d_name}'"}, data: {turbo_action: "replace"} }
      format.json { head :no_content }
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
