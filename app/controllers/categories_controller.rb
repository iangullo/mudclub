# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
class CategoriesController < ApplicationController
	before_action :set_category, only: %i[ show edit update destroy ]

	# GET /categories or /categories.json
	def index
		check_access(roles: [:admin])
		@categories = Category.real
		@fields     = create_fields(helpers.category_title_fields(title: I18n.t("category.many")))
		@grid       = create_grid(helpers.category_grid)
	end

	# GET /categories/1 or /categories/1.json
	def show
		check_access(roles: [:admin])
		@fields = create_fields(helpers.category_show_fields)
		@submit = create_submit(submit: current_user.admin? ? edit_category_path(@category) : nil)
	end

	# GET /categories/new
	def new
		check_access(roles: [:admin])
		@category = Category.new
		prepare_form(title: I18n.t("category.new"))
	end

	# GET /categories/1/edit
	def edit
		check_access(roles: [:admin])
		prepare_form(title: I18n.t("category.edit"))
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

		# prepare a form to edit/create a Category
		def prepare_form(title:)
			@fields = create_fields(helpers.category_form_fields(title:))
			@submit = create_submit
		end

		# Only allow a list of trusted parameters through.
		def category_params
			params.require(:category).permit(:age_group, :sex, :min_years, :max_years, :rules)
		end
end
