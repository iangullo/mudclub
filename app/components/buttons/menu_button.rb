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
# MenuButton class for ButtonComponents manages menu & login buttons
class MenuButton < AaBaseButton
	def initialize(button)
		super(button)
		@b_class += ["inline-flex", "font-bold", "m-1"]
		@d_class += ["shadow", "font-bold"]
		@d_class += set_colour(wait: "blue-900", light: "blue-700", text: "gray-200", high: "white")
		@i_class  = ["max-h-7", "min-h-5", "align-middle"]
		if @bdata[:kind]=="login"
			@bdata[:flip]   = true
			@bdata[:icon] ||= "login.svg"
			@bdata[:type]   = "submit"
		end
		set_data
	end
end