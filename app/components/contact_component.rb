# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
# ContactComponent - ViewComponent to manage flexible buttons to launch contact
# actions dependent on email address, phone number and client device type.
# initialised with: 
# => "email": email address - for mail_to: links
# => "phone": phone number
# => "device": client device type
# frozen_string_literal: true

class ContactComponent < ApplicationComponent
	def initialize(email:, phone:, device:)
		@email = ButtonComponent.new(button: {kind: "email", value: email}) if email.presence
		if phone.presence
			@call     = ButtonComponent.new(button: {kind: "call", value: phone}) if device == "mobile"
			@whatsapp = ButtonComponent.new(button: {kind: "whatsapp", value: phone, web: (device=="desktop")})
		end
	end
end
