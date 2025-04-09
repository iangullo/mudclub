# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
# ContactComponent - ViewComponent to manage flexible buttons to launch contact
# actions dependent on email address, phone number and client device type.
# initialised with:
# => "website": website of the contact - open a new tab with their website
# => "email": email address - for mail_to: links
# => "phone": phone number
# => "device": client device type
# frozen_string_literal: true

class ContactComponent < ApplicationComponent
	def initialize(website: nil, email:, phone:, device:)
		@email   = ButtonComponent.new(kind: :email, value: email) if email.presence
		@website = ButtonComponent.new(kind: :link, icon: "website.svg", url: website, tab: true) if website.presence
		if phone.presence
			@call     = ButtonComponent.new(kind: :call, value: phone) if device == "mobile"
			@whatsapp = ButtonComponent.new(kind: :whatsapp, value: phone, web: (device=="desktop"))
		end
	end

	def call	# render HTML
    content_tag(:div, class: "inline-flex items-center text-xs") do
      render_button(@website)
      render_button(@email)
      render_button(@call)
      render_button(@whatsapp)
    end
	end

	private
		# render one button
		def render_button(button)
			concat(render(button)) if button
		end
end
