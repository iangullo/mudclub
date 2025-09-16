# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
# Managament of MudClub home page for users
class HomeController < ApplicationController
	def index
		if current_user.present?
			if u_manager? || u_secretary?	# manage host club
				redirect_to club_path(u_clubid), data: { turbo_action: "replace" }
			elsif u_coach? || u_player?
				if u_coach?
					@coach = current_user.coach
					title  = helpers.coach_title
				elsif u_player?
					@player = current_user.player
					title   = helpers.player_title
				end
				@title = create_fields(title)
				@table = create_table(helpers.team_table(teams: current_user.team_list))
			elsif u_admin? # manage server
				redirect_to home_server_path
			end
		else
			@login_fields = create_fields(helpers.home_closed)
		end
	end

	def about
		@title  = create_fields(helpers.home_about_title)
		@fields = create_fields(helpers.home_about)
		@submit = create_submit(submit: nil)
	end

	def log
		if check_access(roles: [ :admin, :manager ])
			if u_admin?
				actions = UserAction.logs
			else
				actions = UserAction.where(user_id: u_club.users.pluck(:id)).order(updated_at: :desc)
			end
			title = helpers.home_admin_title(icon: { concept: "actions", size: "50x50" }, subtitle: I18n.t("server.log"))
			title.last << helpers.button_field({ kind: :clear, url: home_clear_path }) unless actions.empty?
			page  = paginate(actions)	# paginate results
			table = helpers.home_actions_table(actions: page)
			create_index(title:, table:, page:, retlnk: "/")
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	def clear
		if check_access(roles: [ :admin ])
			UserAction.clear
			respond_to do |format|
				a_desc = I18n.t("user.cleared")
				format.html { redirect_to home_log_path, status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	def server
		if u_admin? # manage server
			@title  = create_fields(helpers.home_admin_title(subtitle: I18n.t("server.single")))
			@fields = create_fields(helpers.home_admin)
		end
	end
end
