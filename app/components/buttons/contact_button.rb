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
# frozen_string_literal: true
#
# ContactButton class for ButtonComponents manages call, email, phone kinds
class ContactButton < BaseButton
	def initialize(button)
		super(button)
		@bdata[:icon] ||= set_icon
		@bdata[:url]    = set_url
		@d_class += ["shadow"]
		@d_class += set_colour(wait: "gray-100", light: "gray-300", text: "gray-700", high: "gray-700")
		@i_class  = ["max-h-7", "min-h-5", "align-middle"]
		set_data
	end

	private
		def set_icon
			case @bdata[:kind]
			when "call"
				"phone.svg"
			when "email"
				"at.svg"
			when "whatsapp"
				"WhatsApp.svg"
			end
		end

		def set_url
			case @bdata[:kind]
			when "call"
				"tel:#{@bdata[:value]}"
			when "email"
				"mailto:#{@bdata[:value]}"
			when "whatsapp"
				if @bdata[:web]
					@bdata[:tab] = true
					burl = "https://web.whatsapp.com/"
				else
					burl = "whatsapp://"
				end
				burl + "send?phone=#{@bdata[:value].delete(' ')}"
			end
		end
end