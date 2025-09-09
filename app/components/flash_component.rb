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
# frozen_string_literal: true

# FlashComponent - manage flash notifications
class FlashComponent < ApplicationComponent
	def initialize(notice)
		@count  = @count ? @count + 1 : 1
		@notice = notice.class==String ? notice : notice["message"]
		@kind   = notice.class==String ? :info : notice[:kind]
		case @kind
		when :error
			color = "red"
		when :success
			color = "indigo"
		else
			color = "gray"
		end
		@d_class = "flex p-4 mb-4 bg-#{color}-100 text-#{color}-900 text-sm rounded-lg shadow-lg"
		@b_class = "ml-auto -mx-1.5 -my-1.5 rounded-lg focus:ring-2 focus:ring-#{color}-400 p-1.5 hover:bg-#{color}-200 inline-flex h-8 w-8"
	end

	# render component
	def call
		content_tag(:div, class: "absolute float-right top-12 right-2 p-2 m-2") do
			content_tag(:div, id: "alert-#{@count}", class: @d_class, role: "alert", data: { dismiss_duration: 300 }) do
				concat @notice
				concat dismiss_button
			end
		end
	end

	private
		# dismiss button for Flash notices
		def dismiss_button
			content_tag(:button, type: "button", class: @b_class, "data-dismiss-target": "#alert-#{@count}", "aria-label": "Close") do
				content_tag(:svg, class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20", xmlns: "http://www.w3.org/2000/svg") do
					content_tag(:path,
						"",
						fill_rule: "evenodd",
						d: "M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z",
						clip_rule: "evenodd"
					)
				end
			end
		end
end
