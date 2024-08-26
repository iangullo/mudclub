# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
# Managament on MudClub sports
class SportsController < ApplicationController
	before_action :set_sport

	# Sport index for mudclub admins
	def index
		if check_access(roles: [:admin])
			title = helpers.home_admin_title(title: I18n.t("sport.many"))
			grid  = helpers.sports_grid
			create_index(title:, grid:, retlnk: "/")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# View club details
	def show
		if check_access(roles: [:admin])
			@fields = create_fields(helpers.sports_show_fields)
			@submit = create_submit(close: "back", submit: nil, retlnk: :back)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# Cannot create new sports yet
	def new
		if check_access(roles: [:admin])
			redirect_to sport_path(@sport.id), data: {turbo_action: "replace"}
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# Cannot edit Sports yet
	def edit
		if check_access(roles: [:admin])
			redirect_to sport_path(@sport.id), data: {turbo_action: "replace"}
#			@fields = create_fields(helpers.sports_form_fields(title: I18n.t("sport.edit")))
#			@submit = create_submit
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# Cannot create new sports yet
	def create
		if check_access(roles: [:admin])
			redirect_to sport_path(@sport.id), data: {turbo_action: "replace"}
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# Cannot update Sports yet
	def update
		if check_access(roles: [:admin])
			redirect_to sport_path(@sport.id), data: {turbo_action: "replace"}
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

	# View club details
	def rules
		if check_access(roles: [:admin])
			@title  = create_fields(helpers.sport_rules_title(I18n.t("sport.rules")))
			@fields = create_fields(helpers.sports_rules_fields)
			@submit = create_submit(submit: nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_sport
			@sport  = Sport.fetch(params[:id].presence)
		end

		# prepare a form to edit/create a Category
		def prepare_form(title:)
			@fields = create_fields(helpers.sports_form_fields(title:))
			@submit = create_submit(retlnk: :back)
		end

		# Only allow a list of trusted parameters through.
		def category_params
			params.require(:sport).permit(:name, :retlnk)
		end
end
