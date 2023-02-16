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

# AccordionComponent - ViewComponent to render an accordion of
# content. Receives accordion: as starting point:
# => accordion: a Hash with the follwing fields (at least)
#			* title: (string of accordion title to print)
#			* h_class: Tailwind class for accordion header row
#			* i_class: Tailwind classes to use with each object header
#			* t_class: Tailwind classes to use with accordion tail row (if needed)
#			* tail: content to display in optional tail row.
#			* objects: Array of objectss to display in accordion. Each with:
#				-> head: label to display in accordion button
#				-> head_id: unique identifier of object button in accordion
#				-> body_id: unique identifier to expand/collapse object content
#				-> content: object content to render in collapsible section
class AccordionComponent < ApplicationComponent
	def initialize(accordion:)
		@accordion = accordion
	end
end
