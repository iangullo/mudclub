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

# AccordionComponent - ViewComponent to render an accordion of
# content. Receives **attrs as starting point, containing (at
# least):
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
	H_CLASS = "font-semibold text-left text-indigo-900"
	T_CLASS = "font-semibold text-right text-indigo-900"
	I_CLASS = "flex justify-between items-center p-1 w-full bg-gray-100 text-left text-gray-700 rounded-md hover:bg-gray-500 hover:text-indigo-100 focus:bg-indigo-900 focus:text-gray-200"
	O_CLASS = "py px-2 rounded-lg border-2 border-indigo-900 hidden"

	def initialize(title:, tail: nil, objects: [])
		@title = title
		@tail  = tail
		i      = 1
		@objects = objects
		@objects.each do |obj|
			obj[:head_id] = "accordion-collapse-heading-" + i.to_s
			obj[:body_id] = "accordion-collapse-body-" + i.to_s
			i = i +1
		end
	end

	# render the component
	def call
    content_tag(:div, id: "accordion-collapse", data: { accordion: "collapse" }) do
			content_tag(:h2, @title, class: H_CLASS) +
			@objects.map { |obj| accordion_object(obj) }.join.html_safe +
			content_tag(:div, @tail, class: T_CLASS) if @tail.present?
		end
	end

	private
		# render one accordion element
		def accordion_object(obj)
			content_tag(:h2, id: obj[:head_id]) do
				button_tag(type: "button", class: I_CLASS, data: { accordion_target: "##{obj[:body_id]}" }, aria: { expanded: false, controls: obj[:body_id] }) do
					content_tag(:span, obj[:head]) +
					content_tag(:svg, nil, data: { accordion_icon: true }, class: "w-6 h-6 rotate-180 shrink-0", fill: "currentColor", viewBox: "0 0 20 20", xmlns: "http://www.w3.org/2000/svg") do
						tag(:path, fill_rule: "evenodd", d: "M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z", clip_rule: "evenodd")
					end
				end +
				content_tag(:div, class: O_CLASS, id: obj[:body_id], aria: { labelledby: obj[:head_id] }) do
					if obj[:content].class == FieldsComponent
						render(obj[:content])
					else
						obj[:content]
					end
				end
			end
		end
end
