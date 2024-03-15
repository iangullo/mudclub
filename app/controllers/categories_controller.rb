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
	before_action :set_sport
	before_action :set_category, only: %i[ show edit update destroy ]

	# GET /categories or /categories.json
	def index
		if check_access(roles: [:admin])
			@categories = Category.for_sport(@sport.id)
			title = helpers.category_title_fields(title: I18n.t("category.many"))
			grid  = helpers.category_grid
			create_index(title:, grid:)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /categories/1 or /categories/1.json
	def show
		if check_access(roles: [:admin])
			@fields = create_fields(helpers.category_show_fields)
			@submit = create_submit(submit: current_user.admin? ? edit_sport_category_path(@sport, @category) : nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /categories/new
	def new
		if check_access(roles: [:admin])
			@category = @sport.categories.build
			prepare_form(title: I18n.t("category.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /categories/1/edit
	def edit
		if check_access(roles: [:admin])
			prepare_form(title: I18n.t("category.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /categories or /categories.json
	def create
		if check_access(roles: [:admin])
			@category = Category.new(sport_id: @sport.id)
			respond_to do |format|
				@category.rebuild(category_params)
				if @category.save
					a_desc = "#{I18n.t("category.created")} '#{@category.name}'"
					register_action(:created, a_desc, url: sport_category_path(@sport,@category), modal: true)
					format.html { redirect_to sport_path(@sport.id), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
					format.json { render :show, status: :created, location: sport_path(@sport.id) }
				else
					prepare_form(title: I18n.t("category.new"))
					format.html { render :new, status: :unprocessable_entity }
					format.json { render json: @category.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to sport_categories_path(@sport), data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /categories/1 or /categories/1.json
	def update
		if check_access(roles: [:admin])
			respond_to do |format|
				@category.rebuild(category_params)
				if @category.changed?
					if @category.save
						a_desc = "#{I18n.t("category.updated")} '#{@category.name}'"
						register_action(:updated, a_desc, url: sport_category_path(@sport,@category), modal: true)
						format.html { redirect_to sport_path(@sport.id), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :ok, location: sport_path(@sport.id) }
					else
						prepare_form(title: I18n.t("category.edit"))
						format.html { render :edit, status: :unprocessable_entity }
						format.json { render json: @category.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to sport_path(@sport.id), notice: no_data_notice, data: {turbo_action: "replace"}}
					format.json { render :index, status: :ok, location: sport_path(@sport.id) }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /categories/1 or /categories/1.json
	def destroy
		if check_access(roles: [:admin])
			c_name = @category.name
			@category.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("category.deleted")} '#{c_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to sport_path(@sport.id), status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_sport
			@sport = Sport.fetch(params[:sport_id])
		end

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
			params.require(:category).permit(:age_group, :sex, :min_years, :max_years, :rules, :sport_id)
		end
end
