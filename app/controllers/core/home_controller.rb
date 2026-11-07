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
# Managament of MudClub home page for users (& visitors?)
class HomeController < ApplicationController
	def index
		if current_user
			@policy = HomePolicy.new(current_user, club: @club)
			h_path  =
				if u_admin? # manage server
					server_path
				elsif @policy.manages_club?	# manage club
					club_path(@club)
				elsif @policy.club_member?
					path_for(current_user)
				else
					path_for(current_user)
				end
			redirect_to h_path, data: { turbo_action: "replace" }
		elsif Server.public_clubs_enabled?
			@clubs  = Club.publicly_listed
			if @clubs.size == 1
				redirect_to path_for(@clubs.first)
			elsif Server.public_directory_enabled?
				@fields = create_fields(helpers.home_anonymous_fields)
				page    = paginate(@clubs)
				@table  = create_table(helpers.club_table(clubs: page))
			end
		else
			@fields = create_fields(helpers.home_closed)
		end
	end

	def my_registrations
		@registrations = collect_my_registrations
		@title         = create_fields(helpers.my_registrations_title)
		if @registrations.any?
			@table = create_table(
				helpers.my_registrations_table(
					@registrations,
					tokens: session_registration_tokens
				)
			)
		else
			@fields = create_fields(helpers.my_registrations_empty)
		end

		@submit = create_submit(close: :back, retlnk: root_path)
	end

	private
		def collect_my_registrations
			tokens = session_registration_tokens
			ids    = tokens.keys

			if current_user&.person_id.present?
				submitted = Registration.where(submitted_by_id: current_user.person_id).pluck(:id)
				ids = (ids + submitted).uniq
			end

			Registration
				.where(id: ids)
				.includes(:club, :requested_team)
				.order(created_at: :desc)
				.to_a
		end

		def session_token_for(registration_id)
			session_registration_tokens[registration_id] ||
				session_registration_tokens[registration_id.to_s]
		end
end
