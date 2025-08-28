# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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

# app/components/traffic_light_component.rb
# TrafficLightComponent - ViewComponent to show a traffic light indicator
class TrafficLightComponent < ViewComponent::Base
	def initialize(status:, size: :medium)
		@status = status
		@size_classes = {
			small: "w-3 h-3",
			medium: "w-4 h-4",
			large: "w-6 h-6"
		}[size]
	end

	def color_classes
		{
			red: "bg-red-500 border-red-600",
			orange: "bg-yellow-700 border-yellow-800",
			yellow: "bg-yellow-400 border-yellow-500",
			lime: "bg-green-300 border-green-400",
			green: "bg-green-500 border-green-600",
			default: "bg-gray-300 border-gray-400"
		}[@status] || "bg-gray-300 border-gray-400"
	end

	def color_titles
		{
			red: "not_started",
			orange: "starting",
			yellow: "in_progress",
			lime: "good",
			green: "completed",
			default: "inactive"
		}[@status] || "inactive"
	end

	def call
		content_tag(:div, "", class: "rounded-full border-2 #{@size_classes} #{color_classes} inline-block", title: I18n.t("status.#{color_titles}"))
	end
end
