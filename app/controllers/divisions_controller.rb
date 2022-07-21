class DivisionsController < ApplicationController
  before_action :set_division, only: %i[ show edit update destroy ]

  # GET /divisions or /divisions.json
  def index
    if current_user.present? and current_user.admin?
      @divisions = Division.real
      @fields    = title_fields(I18n.t("division.many"))
      @grid      = division_grid
    else
      redirect_to "/"
    end
  end

  # GET /divisions/1 or /divisions/1.json
  def show
    redirect_to "/" unless current_user.present? and current_user.admin?
    @fields = title_fields(I18n.t("division.single"))
    @fields << [{kind: "subtitle", value: @division.name}]
  end

  # GET /divisions/new
  def new
    if current_user.present? and current_user.admin?
      @division = Division.new
      @fields   = form_fields(I18n.t("division.new"))
    else
      redirect_to "/"
    end
  end

  # GET /divisions/1/edit
  def edit
    redirect_to "/" unless current_user.present? and current_user.admin?
    @fields   = form_fields(I18n.t("division.edit"))
  end

  # POST /divisions or /divisions.json
  def create
    if current_user.present? and current_user.admin?
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
    else
      redirect_to "/"
    end
  end

  # PATCH/PUT /divisions/1 or /divisions/1.json
  def update
    if current_user.present? and current_user.admin?
      respond_to do |format|
        if @division.update(division_params)
          format.html { redirect_to divisions_url, notice: {kind: "success", message: "#{I18n.t("division.updated")} '#{@division.name}'"}, data: {turbo_action: "replace"} }
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
        format.html { redirect_to divisions_url, status: :see_other, notice: {kind: "success", message: "#{I18n.t("division.deleted")} '#{d_name}'"}, data: {turbo_action: "replace"} }
        format.json { head :no_content }
      end
    else
      redirect_to "/"
    end
  end

  private
  	# return icon and top of FieldsComponent
  	def title_fields(title, cols: nil)
      title_start(icon: "division.svg", title: title, cols: cols)
  	end

    # return FieldsComponent @fields for forms
    def form_fields(title)
      res = title_fields(title, cols: 3)
      res << [{kind: "text-box", key: :name, value: @division.name, cols: 3}]
      res
    end

		# return grid for @divisions GridComponent
    def division_grid
      title = [{kind: "normal", value: I18n.t("division.name")}]
			title << {kind: "add", url: new_division_path, frame: "modal"} if current_user.admin?

      rows = Array.new
      @divisions.each { |div|
        row = {url: edit_division_path(div), frame: "modal", items: []}
        row[:items] << {kind: "normal", value: div.name}
        row[:items] << {kind: "delete", url: division_path(div), name: div.name} if current_user.admin?
        rows << row
      }
      {title: title, rows: rows}
    end

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
