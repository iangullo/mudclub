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
# Managament of MudClub server sports
class SportsController < ApplicationController
	before_action :set_sport

	# Sport index for mudclub admins
	def index
		if check_access(roles: [:admin])
			title = helpers.home_admin_title(title: I18n.t("sport.many"))
			grid  = helpers.sports_grid
			create_index(title:, grid:, retlnk: base_lnk("/"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# View sport details
	def show
		if @sport && check_access(roles: [:admin])
			@fields = create_fields(helpers.sports_show_fields)
			@submit = create_submit(close: "back", submit: nil, retlnk: base_lnk(sports_path(rdx: @rdx)))
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
		if @sport && check_access(roles: [:admin])
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
			redirect_to cru_return, data: {turbo_action: "replace"}
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# Cannot update Sports yet
	def update
		if @sport && check_access(roles: [:admin])
			redirect_to cru_return, data: {turbo_action: "replace"}
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# Remove a sport
	def destroy
		if @sport && check_access(roles: [:admin])
			redirect_to sports_path(rdx: @rdx), data: {turbo_action: "replace"}
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# View sport rules
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
		# wrapper to set return link for create && update operations
		def cru_return
			sport_path(@sport.id, rdx: @rdx)
		end

		# prepare a form to edit/create a Sport
		def prepare_form(action)
			@fields = create_fields(helpers.sports_form_fields(title: I18n.t("sport.#{action}")))
			@submit = create_submit(retlnk: base_lnk("/"))
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_sport
			@sport  = Sport.fetch(params[:id].presence)
		end

		# Only allow a list of trusted parameters through.
		def sport_params
			params.require(:sport).permit(:name , :rdx, :retlnk)
		end
end
