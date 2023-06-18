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
# NavButton class for ButtonComponents manages "back", "forward" kinds
class NavButton < AaBaseButton
	def initialize(button)
		super(button)
		case @bdata[:kind]
		when "forward"
			@bdata[:icon]  ||= "forward.svg"
			@bdata[:label] ||= I18n.t("action.next")
		when "back"
			@bdata[:icon]    = "back.svg"
			@bdata[:label] ||= I18n.t("action.previous")
			@bdata[:replace] = true
		end
		@d_class += ["shadow", "font-semibold"]
		@d_class += set_colour(colour: "gray")
		@b_class += ["m-1", "inline-flex", "align-middle"]
		@i_class  = ["max-h-7", "min-h-5", "align-middle"]
		set_data
	end
end