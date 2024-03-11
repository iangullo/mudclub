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
class HomeController < ApplicationController
	def index
		if current_user.present?
			if u_manager?	# manage host club
				redirect_to club_path(u_clubid), data: {turbo_action: "replace"}
			elsif u_admin?
				@fields = create_fields(helpers.home_admin_fields)
			elsif u_coach?
				@coach  = current_user.coach
				@fields = create_fields(helpers.coach_show_fields)
				@grid   = create_grid(helpers.team_grid(teams: @coach.team_list))
			elsif u_player?
				start_date = (params[:start_date] ? params[:start_date] : Date.today.at_beginning_of_month).to_date
				@player = current_user.player
				title   = helpers.player_show_fields
				@fields = create_fields(title)
				teams   = helpers.team_grid(teams: current_user.team_list)
				@grid   = create_grid(teams) if teams
			end
		end

	end

	def about
		@title  = create_fields(helpers.home_about_title)
		@fields = create_fields(helpers.home_about_fields)
		@submit = create_submit(submit: nil)
	end

	def log
		if check_access(roles: [:admin, :manager])
			if u_admin?
				actions = UserAction.logs
			else
				actions = UserAction.where(user_id: u_club.users.pluck(:id)).order(updated_at: :desc)
			end
			title   = helpers.home_admin_title(icon: "user_actions.svg", title: I18n.t("server.log"))
			title.last << helpers.button_field({kind: "clear", url: home_clear_path}) unless actions.empty?
			@title  = create_fields(title)
			@grid   = create_grid(helpers.home_actions_grid(actions:))
			@submit = create_submit(close: "back", retlnk: :back, submit: nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	def clear
		if check_access(roles: [:admin])
			UserAction.clear
			respond_to do |format|
				a_desc = I18n.t("user.cleared")
				format.html { redirect_to home_log_path, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end
end
