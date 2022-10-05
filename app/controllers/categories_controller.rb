class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ show edit update destroy ]

  # GET /categories or /categories.json
  def index
    check_access(roles: [:admin])
    @categories = Category.real
    @fields     = helpers.category_title_fields(title: I18n.t("category.many"))
    @grid       = helpers.category_grid(categories: @categories)
  end

  # GET /categories/1 or /categories/1.json
  def show
    check_access(roles: [:admin])
    @fields = helpers.category_show_fields(category: @category)
  end

  # GET /categories/new
  def new
    check_access(roles: [:admin])
    @category = Category.new
    @fields  = helpers.category_form_fields(title: I18n.t("category.new"), category: @category)
  end

  # GET /categories/1/edit
  def edit
    check_access(roles: [:admin])
    @fields  = helpers.category_form_fields(title: I18n.t("category.edit"), category: @category)
  end

  # POST /categories or /categories.json
  def create
    check_access(roles: [:admin])
    @category = Category.new(category_params)
    respond_to do |format|
      if @category.save
        format.html { redirect_to categories_url, notice: helpers.flash_message("#{I18n.t("category.created")} '#{@category.name}'", "success"), data: {turbo_action: "replace"} }
        format.json { render :index, status: :created, location: categories_url }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /categories/1 or /categories/1.json
  def update
    check_access(roles: [:admin])
    respond_to do |format|
      if @category.update(category_params)
        format.html { redirect_to categories_url, notice: helpers.flash_message("#{I18n.t("category.updated")} '#{@category.name}'", "success"), data: {turbo_action: "replace"} }
        format.json { render :index, status: :ok, location: categories_url }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1 or /categories/1.json
  def destroy
    check_access(roles: [:admin])
    c_name = @category.name
    prune_teams
    @category.destroy
    respond_to do |format|
      format.html { redirect_to categories_url, status: :see_other, notice: helpers.flash_message("#{I18n.t("category.deleted")} '#{c_name}'"), data: {turbo_action: "replace"} }
      format.json { head :no_content }
    end
  end

  private
    # prune teams from a category to be deleted
    def prune_teams
      @category.teams.each { |t|
        t.category=Category.find(0)  # de-allocate teams
        t.save
      }
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_category
      @category = Category.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def category_params
      params.require(:category).permit(:age_group, :sex, :min_years, :max_years, :rules)
    end
end
