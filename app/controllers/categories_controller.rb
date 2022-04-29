class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ show edit update destroy ]

  # GET /categories or /categories.json
  def index
    if current_user.present? and current_user.admin?
      @categories = Category.real
    else
			redirect_to "/"
		end
  end

  # GET /categories/1 or /categories/1.json
  def show
    redirect_to "/" unless current_user.present? and current_user.admin?
  end

  # GET /categories/new
  def new
    if current_user.present? and current_user.admin?
      @category = Category.new
    else
      redirect_to "/"
    end
  end

  # GET /categories/1/edit
  def edit
    redirect_to "/" unless current_user.present? and current_user.admin?
  end

  # POST /categories or /categories.json
  def create
    if current_user.present? and current_user.admin?
      @category = Category.new(category_params)

      respond_to do |format|
        if @category.save
          format.html { redirect_to categories_url, notice: t(:cat_created) + "'#{@category.name}'" }
          format.json { render :index, status: :created, location: categories_url }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @category.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to "/"
    end
  end

  # PATCH/PUT /categories/1 or /categories/1.json
  def update
    if current_user.present? and current_user.admin?
      respond_to do |format|
        if @category.update(category_params)
          format.html { redirect_to categories_url, notice: t(:cat_updated) + "'#{@category.name}'" }
          format.json { render :index, status: :ok, location: categories_url }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @category.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to "/"
    end
  end

  # DELETE /categories/1 or /categories/1.json
  def destroy
    if current_user.present? and current_user.admin?
      c_name = @category.name
      prune_teams
      @category.destroy
      respond_to do |format|
        format.html { redirect_to categories_url, notice: t(:cat_deleted) + "'#{c_name}'" }
        format.json { head :no_content }
      end
    else
      redirect_to "/"
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
      params.require(:category).permit(:name, :sex, :min_years, :max_years)
    end
end
