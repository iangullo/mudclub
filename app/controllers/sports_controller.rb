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
# Managament on MudClub sports
class SportsController < ApplicationController
	before_action :set_sport, only: %i[ show edit update destroy ]

	# Club index for mudclub admins
	def index
		if check_access(roles: [:admin])
			title = helpers.home_admin_title
			title << [{kind: "side-cell", value: I18n.t("sport.many"), align: "center", cols: 2}]
			@fields = create_fields(title)
			@grid   = create_grid(helpers.sports_grid)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# View club details
	def show
		if check_access(roles: [:manager])
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# Prepare a new club
	def new
		if check_access(roles: [:admin])
			@sport = Sport.new
			prepare_form(title: I18n.t("action.create"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# used to edit a club
	def edit
		if check_access(roles: [:admin])
			prepare_form(title: I18n.t("action.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# View sport details
	def create
		if check_access(roles: [:admin])
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# Update sport details
	def update
		if check_access(roles: [:admin])
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# Remove a club
	def destroy
		if check_access(roles: [:admin])
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_sport
			sport_id = params[:id].presence
			@sport   = Sport.find_by_id(sport_id.to_i) if sport_id
		end

		# prepare a form to edit/create a Category
		def prepare_form(title:)
			@fields = create_fields(helpers.sports_form_fields(title:))
			@submit = create_submit
		end

		# Only allow a list of trusted parameters through.
		def category_params
			params.require(:sport).permit(:name, :retlnk)
		end
end
