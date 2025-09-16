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

# ModalPieComponent - specific Modal ViewComponent for pie charts
class ModalPieComponent < ApplicationComponent
		# Include Chartkick helpers
		include Chartkick::Helper

	def initialize(header:, chart: {})
		@pie_header  = header
		@chart_title = chart[:title]
		@chart_data  = chart[:data]
	end

	def call	# render as HTML
		render ModalComponent.new(simple: true) do
			render FieldsComponent.new(@pie_header)
			pie_chart(@chart_data, title: @chart_title, legend: "bottom")
		end
	end
end
