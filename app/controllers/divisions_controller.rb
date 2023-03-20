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
class DivisionsController < ApplicationController
	before_action :set_division, only: %i[ show edit update destroy ]

	# GET /divisions or /divisions.json
	def index
		check_access(roles: [:admin])
		@divisions = Division.real
		@fields    = create_fields(helpers.division_title_fields(title: I18n.t("division.many")))
		@grid      = create_grid(helpers.division_grid)
	end

	# GET /divisions/1 or /divisions/1.json
	def show
		check_access(roles: [:admin])
		fields  = helpers.division_title_fields(title: I18n.t("division.single"))
		fields << [{kind: "subtitle", value: @division.name}]
		@fields = create_fields(fields)
		@submit = create_submit(submit: current_user.admin? ? edit_division_path(@division) : nil)
	end

	# GET /divisions/new
	def new
		check_access(roles: [:admin])
		@division = Division.new
		prepare_form(title: I18n.t("division.new"))
	end

	# GET /divisions/1/edit
	def edit
		check_access(roles: [:admin])
		prepare_form(title: I18n.t("division.edit"))
	end

	# POST /divisions or /divisions.json
	def create
		check_access(roles: [:admin])
		@division = Division.new(division_params)
		respond_to do |format|
			if @division.save
				format.html { redirect_to divisions_url, notice: helpers.flash_message("#{I18n.t("division.created")} '#{@division.name}'", "success"), data: {turbo_action: "replace"} }
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
				format.html { redirect_to divisions_url, notice: helpers.flash_message("#{I18n.t("division.updated")} '#{@division.name}'", "success"), data: {turbo_action: "replace"} }
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
			format.html { redirect_to divisions_url, status: :see_other, notice: helpers.flash_message("#{I18n.t("division.deleted")} '#{d_name}'"), data: {turbo_action: "replace"} }
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

		# prepare elements to edit/create a new division
		def prepare_form(title:)
			@fields = create_fields(helpers.division_form_fields(title:))
			@submit = create_submit
		end

		# Only allow a list of trusted parameters through.
		def division_params
			params.require(:division).permit(:name)
		end
end
