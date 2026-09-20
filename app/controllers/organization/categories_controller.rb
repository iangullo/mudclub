# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
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
# Managament of MudClub server sport categories
class CategoriesController < ApplicationController
	before_action :set_sport
	before_action :set_category, only: %i[ show edit update destroy ]

	# GET /categories or /categories.json
	def index
		@policy = check_policy!(CategoryPolicy)

		@categories = Category.for_sport(@sport.id)
		title = helpers.category_title(title: Category.label(:plural))
		table = helpers.category_table
		create_index(title:, table:)
	end

	# GET /categories/1 or /categories/1.json
	def show
		@policy = check_policy!(CategoryPolicy, record: @category)

		@fields = create_fields(helpers.category_show)
		@submit = create_submit(submit: current_user.admin? ? edit_path_for(@category, owner: @sport) : nil)
	end

	# GET /categories/new
	def new
		@policy = check_policy!(CategoryPolicy)

		@category = @sport.categories.build
		prepare_form(:create)
	end

	# GET /categories/1/edit
	def edit
		@policy = check_policy!(CategoryPolicy, record: @category)

		prepare_form(:edit)
	end

	# POST /categories or /categories.json
	def create
		@policy = check_policy!(CategoryPolicy)

		@category = Category.new(sport_id: @sport.id)
		respond_to do |format|
			@category.rebuild(category_params)
			if @category.save
				a_desc = "#{Category.msg(:created)} '#{@category.name}'"
				register_action(:created, a_desc, url: path_for(@category, owner: @sport), modal: true)
				format.html { redirect_to path_for(@sport), notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
				format.json { render :show, status: :created, location: path_for(@sport) }
			else
				prepare_form("new")
				format.html { render :new, status: :unprocessable_entity }
				format.json { render json: @category.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /categories/1 or /categories/1.json
	def update
		@policy = check_policy!(CategoryPolicy, record: @category)

		respond_to do |format|
			@category.rebuild(category_params)
			if @category.changed?
				if @category.save
					a_desc = "#{Category.msg(:updated)} '#{@category.name}'"
					register_action(:updated, a_desc, url: path_for(@category, owner: @sport), modal: true)
					format.html { redirect_to path_for(@sport), notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
					format.json { render :show, status: :ok, location: path_for(@sport) }
				else
					prepare_form("edit")
					format.html { render :edit, status: :unprocessable_entity }
					format.json { render json: @category.errors, status: :unprocessable_entity }
				end
			else
				format.html { redirect_to path_for(@sport), notice: no_data_notice, data: { turbo_action: "replace" } }
				format.json { render :index, status: :ok, location: path_for(@sport) }
			end
		end
	end

	# DELETE /categories/1 or /categories/1.json
	def destroy
		@policy = check_policy!(CategoryPolicy, record: @category)

		c_name = @category.name
		@category.destroy
		respond_to do |format|
			a_desc = "#{Category.msg(:deleted)} '#{c_name}'"
			register_action(:deleted, a_desc)
			format.html { redirect_to path_for(@sport), status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
			format.json { head :no_content }
		end
	end

	private
		# prepare a form to edit/create a Category
		def prepare_form(action)
			@fields = create_fields(helpers.category_form(title: Category.act(action)))
			@submit = create_submit
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_sport
			@sport = Sport.fetch(params[:sport_id])
		end

		def set_category
			@category = Category.find(params[:id])
		end

		# Only allow a list of trusted parameters through.
		def category_params
			params.require(:category).permit(:age_group, :min_years, :max_years, :rdx, :rules, :sex, :sport_id)
		end
end
