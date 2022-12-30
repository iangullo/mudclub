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
# app/controllers/turbo_devise_controller.rb

class TurboDeviseController < ApplicationController
	class Responder < ActionController::Responder
		def to_turbo_stream
			controller.render(options.merge(formats: :html))
		rescue ActionView::MissingTemplate => error
			if get?
				raise error
			elsif has_errors? && default_action
				render rendering_options.merge(formats: :html, status: :unprocessable_entity)
			else
				redirect_to navigation_location
			end
		end
	end

	self.responder = Responder
	respond_to :html, :turbo_stream
end
