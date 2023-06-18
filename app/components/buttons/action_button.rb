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
# ActionButton class for ButtonComponents
# conceived to manage non-standard action trigger buttons.
class ActionButton < AaBaseButton
	# basic button information
	def initialize(button)
		super(button,form,session)
		@d_class << "shadow"
		@d_class += set_colour(wait: "gray-100", light: "gray-300", text: "gray-700", high: "gray-700")
		@b_class += ["font-bold", "m-1", "inline-flex", "align-middle"] if @bdata[:label]
		set_data
	end
end