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
class RegistrationMailer < ApplicationMailer
	before_action :assign_snapshot

	def created
		@url = anonymous_registration_url(@snapshot)
		mail(to: @snapshot.recipient, subject: t(".subject", club: @snapshot.club))
	end

	def information_requested
		@url = anonymous_registration_url(@snapshot)
		mail(to: @snapshot.recipient, subject: t(".subject", club: @snapshot.club))
	end

	def approved
		@membership = params[:membership]
		mail(to: @snapshot.recipient, subject: t(".subject", club: @snapshot.club))
	end

	def rejected
		@reason = params[:reason]
		mail(to: @snapshot.recipient, subject: t(".subject", club: @snapshot.club))
	end

	def cancelled
		@support_email = Server.support_email
		mail(to: @snapshot.recipient, subject: t(".subject", club: @snapshot.club))
	end

	private
		def assign_snapshot
			@snapshot = params[:snapshot]
		end

		def anonymous_registration_url(snapshot)
			if snapshot.team_id.present?
				club_team_registration_url(snapshot.club_id, snapshot.team_id, snapshot.registration_id, token: snapshot.access_token)
			else
				club_registration_url(snapshot.club_id, snapshot.registration_id, token: snapshot.access_token)
			end
		end
end
