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
		if check_access(roles: [:admin])
			@divisions = Division.real
			@fields    = create_fields(helpers.division_title_fields(title: I18n.t("division.many")))
			@grid      = create_grid(helpers.division_grid)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /divisions/1 or /divisions/1.json
	def show
		if check_access(roles: [:admin], obj: @division)
			fields  = helpers.division_title_fields(title: I18n.t("division.single"))
			fields << [{kind: "subtitle", value: @division.name}]
			@fields = create_fields(fields)
			@submit = create_submit(submit: u_admin? ? edit_division_path(@division) : nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /divisions/new
	def new
		if check_access(roles: [:admin])
			@division = Division.new
			prepare_form(title: I18n.t("division.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /divisions/1/edit
	def edit
		if check_access(roles: [:admin], obj:  @division)
			prepare_form(title: I18n.t("division.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /divisions or /divisions.json
	def create
		if check_access(roles: [:admin])
			@division = Division.new(division_params)
			respond_to do |format|
				if @division.save
					a_desc = "#{I18n.t("division.created")} '#{@division.name}'"
					register_action(:created, a_desc)
					format.html { redirect_to divisions_path, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: divisions_path }
				else
					prepare_form(title: I18n.t("division.new"))
					format.html { render :new, status: :unprocessable_entity }
					format.json { render json: @division.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /divisions/1 or /divisions/1.json
	def update
		if check_access(roles: [:admin], obj: @division)
			respond_to do |format|
				@division.rebuild(division_params)
				if @division.changed?
					if @division.save
						a_desc = "#{I18n.t("division.updated")} '#{@division.name}'"
						register_action(:updated, a_desc)
						format.html { redirect_to divisions_path, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: divisions_path }
					else
						prepare_form(title: I18n.t("division.new"))
						format.html { render :edit, status: :unprocessable_entity }
						format.json { render json: @division.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to divisions_path, notice: no_data_notice, data: {turbo_action: "replace"}}
					format.json { render :index, status: :ok, location: divisions_path }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /divisions/1 or /divisions/1.json
	def destroy
		if check_access(roles: [:admin], obj: @division)
			d_name = @division.name
			prune_teams
			@division.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("division.deleted")} '#{d_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to divisions_path, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
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
			@division = Division.find_by_id(params[:id])
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
