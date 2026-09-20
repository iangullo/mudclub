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
# Managament of MudClub home page for users
class HomeController < ApplicationController
	def index
		if current_user
			@policy = HomePolicy.new(current_user, club: @club)
			h_path  =
				if @policy.manages_club?	# manage host club
					club_path(@club)
				elsif @policy.club_member?
					path_for(current_user)
				elsif u_admin? # manage server
					home_server_path
				else
					path_for(current_user)
				end
			redirect_to h_path, data: { turbo_action: "replace" }
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
		@policy = check_policy!(HomePolicy, club: @club)

		actions =
			if u_admin?
				UserAction.logs
			else
				UserAction.where(user_id: u_club.users.pluck(:id)).order(updated_at: :desc)
			end
		title = helpers.home_admin_title(icon: { concept: "actions", size: "50x50" }, subtitle: I18n.t("server.log"))
		title.last << helpers.button_field({ kind: :clear, url: home_clear_path }) unless actions.empty?
		page  = paginate(actions)	# paginate results
		table = helpers.home_actions_table(actions: page)
		create_index(title:, table:, page:, retlnk: "/")
	end

	def clear
		@policy = check_policy!(HomePolicy)

		UserAction.clear
		respond_to do |format|
			a_desc = I18n.t("user.cleared")
			format.html { redirect_to home_log_path, status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
			format.json { head :no_content }
		end
	end

	def server
		@policy = check_policy!(HomePolicy)
		@title  = create_fields(helpers.home_admin_title(subtitle: I18n.t("server.single")))
		@fields = create_fields(helpers.home_admin)
	end
end
