# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
class SeasonsController < ApplicationController
	before_action :set_season, only: [:index, :show, :edit, :update, :destroy, :locations]

	# GET /seasons
	# GET /seasons.json
	def index
		if check_access(roles: [:admin])
			@seasons = Season.real
			page  = paginate(@seasons)	# paginate results
			title = helpers.season_title_fields(icon: "mudclub.svg", title: I18n.t("season.many"))
			grid  = helpers.season_grid(seasons: page)
			create_index(title:, grid:, page:, retlnk: "/")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /seasons/1
	def show
		if check_access(roles: [:admin])
			@fields = create_fields(helpers.season_fields)
			@submit = create_submit(close: "back", retlnk: seasons_path, submit: edit_season_path, frame: "modal")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /seasons/1/edit
	def edit
		if check_access(roles: [:admin])
			prepare_form(title: I18n.t("season.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /seasons/new
	def new
		if check_access(roles: [:admin])
			@season = Season.new(start_date: Date.today, end_date: Date.today)
			prepare_form(title: I18n.t("season.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /seasons
	# POST /seasons.json
	def create
		if check_access(roles: [:admin])
			@season = Season.new(season_params)
			respond_to do |format|
				if @season.save
					a_desc = "#{I18n.t("season.created")} '#{@season.name}'"
					register_action(:created, a_desc, url: seasons_path)
					format.html { redirect_to seasons_path, notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: seasons_path }
				else
					prepare_form(title: I18n.t("season.new"))
					format.html { render :new }
					format.json { render json: @season.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /seasons/1
	# PATCH/PUT /seasons/1.json
	def update
		if check_access(roles: [:admin])
			respond_to do |format|
				check_locations
				@season.rebuild(season_params)
				if @season.changed?
					if @season.save
						a_desc = "#{I18n.t("season.updated")} '#{@season.name}'"
						register_action(:updated, a_desc, url: season_path(@season))
						format.html { redirect_to season_path(@season), notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: seasons_path}
					else
						prepare_form(title: I18n.t("season.edit"))
						format.html { render :edit }
						format.json { render json: @season.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to seasons_path, notice: no_data_notice, data: {turbo_action: "replace"} }
					format.json { render :index, status: :unprocessable_entity, location: seasons_path }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /seasons/1
	# DELETE /seasons/1.json
	def destroy
		# cannot destroy placeholder season (id ==0)
		if @season.id != 0 && ccheck_access(roles: [:admin])
			s_name = @season.name
			@season.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("season.deleted")} '#{s_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to seasons_path, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		def check_locations
			param_passed(:season, :locations_attributes)&.each do |loc|
				if loc[1][:_destroy] == "1"
					@season.locations.delete(loc[1][:id].to_i)
				else
					l = Location.find(loc[1][:id].to_i)
					@season.locations ? @season.locations << l : @season.locations |= l
				end
			end
		end

		# defines correct retlnk based on params received
		def get_retlnk
			return home_log_path if @rdx==2	# return to log_path
			return season_path(@season) if @season
			return seasons_path
		end

		def set_season
			s_id = params[:id].presence || params[:season_id].presence
			@season = Season.search(s_id) unless @season&.id==s_id&.to_i
		end

		# prepare fields for new/edit season
		def prepare_form(title:)
			@fields = create_fields(helpers.season_form_fields(title:))
			@submit = create_submit
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def season_params
			params.require(:season).permit(
				:id,
				:end_date,
				:log,
				:rdx,
				:start_date,
				locations_attributes: [
					:id,
					:_destroy
				],
				locations: [],
				season_locations: []
			)
		end
end
