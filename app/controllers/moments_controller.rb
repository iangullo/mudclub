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
# Management of timestamped coaching notes on match videos
class MomentsController < ApplicationController
	before_action :set_event

	# GET /events/1/moments/new
	def new
		if moment_editor?
			@moment = @event.moments.build
			@fields = create_fields(helpers.moment_form)
			@submit = create_submit
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# POST /events/1/moments
	def create
		if moment_editor?
			@moment = @event.moments.build(moment_params)
			if @moment.save
				a_desc = "#{I18n.t("moment.created")} #{@moment.time} #{@event.to_s(style: "notice")}"
				register_action(:created, a_desc, url: event_path(@event, rdx: 2))
				notice = helpers.flash_message(a_desc, "success")
			else
				notice = helpers.flash_message(@moment.errors.full_messages.to_sentence, "error")
			end
			redirect_to event_path(@event, rdx: @rdx), notice:, data: { turbo_action: "replace" }
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# DELETE /events/1/moments/1
	def destroy
		moment = @event&.moments&.find_by_id(params[:id])
		if moment && moment_editor?
			moment.destroy
			a_desc = "#{I18n.t("moment.deleted")} #{moment.time} #{@event.to_s(style: "notice")}"
			register_action(:deleted, a_desc)
			redirect_to event_path(@event, rdx: @rdx), status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" }
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	private
		# only coaches of the team and club managers can tag moments of a match
		def moment_editor?
			@event&.match? && user_in_club? && (club_manager?(@event.team.club) || @event.team.has_coach(u_coachid))
		end

		def set_event
			@event = Event.find_by_id(params[:event_id])
		end

		def moment_params
			params.require(:moment).permit(:time, :player_id, :kind, :note)
		end
end
