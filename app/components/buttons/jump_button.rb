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
# JumpButton class for ButtonComponents manages "jump", "link", "location" kinds
class JumpButton < AaBaseButton
	def initialize(button)
		super(button)
		case @bdata[:kind]
		when "jump"
			@d_class += ["m-1", "text-sm"]
		when "location"
			@bdata[:icon] ||= "gmaps.svg"
			@bdata[:tab]    = true
			@d_class << "text-sm"
		end
		@d_class += set_colour(light: "blue-100")
		unless @bdata[:kind]=="jump"
			@b_class += ["font-bold", "m-1", "inline-flex", "align-middle"]
			@i_class  = ["max-h-6", "min-h-4", "align-middle"]
		end
		set_data
	end
end