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
# AddButton class for ButtonComponents manages "add" buttons
class AddButton < BaseButton
	# basic button information
	def initialize(button)
		super(button)
		@bdata[:icon] = "add.svg"
		@i_class = ["max-h-6", "min-h-4", "align-middle"]
		if @bdata[:label]
			@d_class << "shadow"
			@d_class += set_colour(colour: "green")
			@b_class += ["font-bold", "m-1", "inline-flex", "align-middle"]
		else
			@d_class += set_colour(colour: "green")
		end
		set_data
	end
end