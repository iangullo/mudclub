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
					server_path
				else
					path_for(current_user)
				end
			redirect_to h_path, data: { turbo_action: "replace" }
		elsif Server.public_clubs.enabled?
			@clubs  = Club.publicly_listed
			if @clubs.size == 1
				redirect_to path_for(@clubs.first)
			elsif Server.public_directory.enabled?
				@fields = create_fields(helpers.home_anonymous_fields)
				page    = paginate(@clubs)
				@table  = create_table(helpers.club_table(clubs: page))
			end
		else
			@fields = create_fields(helpers.home_closed)
		end
	end
end
