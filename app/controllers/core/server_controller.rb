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
# Managament of MudClub server for admins
class ServerController < ApplicationController
	def about
		@header = create_fields(helpers.server_about_header)
		@fields = create_fields(helpers.server_about_fields)
		@submit = create_submit(submit: nil)
	end

	def log
		@policy = check_policy!(ServerPolicy, club: @club)

		actions =
			if u_admin?
				UserAction.logs
			else
				UserAction.where(user_id: u_club.users.pluck(:id)).order(updated_at: :desc)
			end
		title = helpers.server_header(icon: { concept: :actions, size: "50x50" }, subtitle: Server.fld(:log))
		title.last << helpers.button_field({ kind: :clear, url: clear_log_server_path }) unless actions.empty?
		page  = paginate(actions)	# paginate results
		table = helpers.server_actions_table(actions: page)
		create_index(title:, table:, page:, retlnk: server_path)
	end

	def clear_log
		@policy = check_policy!(ServerPolicy, club: @club)

		UserAction.clear
		respond_to do |format|
			a_desc = UserAction.msg(:cleared)
			format.html { redirect_to log_server_path, status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
			format.json { head :no_content }
		end
	end

	def show
		@policy = check_policy!(ServerPolicy)

		@title  = create_fields(helpers.server_header)
		@fields = create_fields(helpers.server_show_fields)
	end

	def edit
		@policy = check_policy!(ServerPolicy)

		@fields = create_fields(helpers.server_edit_fields)
		@submit = create_submit(retlnk: server_path)
	end

	def update
		@policy = check_policy!(ServerPolicy)

		respond_to do |format|
			notice = Server.rebuild!(server_params) ?
				helpers.flash_message(Server.msg(:updated), "success") :
				helpers.flash_message(Server.msg(:no_change), "error")

			format.html { redirect_to server_path, notice:, data: { turbo_action: "replace" } }
			format.turbo_stream { redirect_to server_path, notice:, status: :ok }
			format.json { render :show, status: :ok, location: server_path }
			format.any { redirect_to server_path, notice: }
		end
	end

	private

	def server_params
		params.require(:server).permit(
			:server_name,
			:support_email,
			:email_signature,
			:default_locale,
			:date_format,
			:admissions,
			:public_clubs_enabled,
			:public_directory_enabled
		)
	end
end
