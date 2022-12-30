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

# FlashComponent - manage flash notifications
class FlashComponent < ApplicationComponent
	def initialize(notice:)
		@count  = @count ? @count + 1 : 1
		@notice = notice.class==String ? notice : notice["message"]
		@kind   = notice.class==String ? "info" : notice["kind"]
		case @kind
		when "error"
			color = "red"
		when "success"
			color = "indigo"
		else
			color = "gray"
		end
		@d_class = "flex p-4 mb-4 bg-#{color}-100 text-#{color}-900 text-sm rounded-lg shadow-lg"
		@b_class = "ml-auto -mx-1.5 -my-1.5 rounded-lg focus:ring-2 focus:ring-#{color}-400 p-1.5 hover:bg-#{color}-200 inline-flex h-8 w-8"
	end
end
