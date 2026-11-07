# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
#			* mode: scroll mode for accordion objects
#			* objects: Array of objectss to display in accordion. Each with:
#				-> head: label to display in accordion button
#				-> head_id: unique identifier of object button in accordion
#				-> body_id: unique identifier to expand/collapse object content
#				-> content: object content to render in collapsible section
class AccordionComponent < ApplicationComponent
		H_CLASS = "font-semibold text-left text-indigo-900"
		T_CLASS = "font-semibold text-right text-indigo-900"
		I_CLASS = "flex justify-between items-center p-1 w-full bg-gray-100 text-left " \
							"text-gray-700 rounded-md hover:bg-gray-500 hover:text-indigo-100 " \
							"focus:bg-indigo-900 focus:text-gray-200"
		O_BASE  = "py-2 px-2 rounded-lg border-2 border-indigo-900"

		BODY_CLASS = {
			plain:  O_BASE,
			scroll: "#{O_BASE} max-h-[70dvh] overflow-y-auto",
			scale:  "#{O_BASE} h-[70dvh] overflow-hidden relative"
		}.freeze

		def initialize(title:, tail: nil, objects: [], form: nil, mode: :scroll)
			@title   = title
			@tail    = tail
			@objects = objects
			@mode    = mode.to_sym
			i = 1
			@objects.each do |obj|
				obj[:head_id] = "accordion-collapse-heading-#{i}"
				obj[:body_id] = "accordion-collapse-body-#{i}"
				i += 1
			end
			self.form = form if form
		end

		def call
			content = []
			content << content_tag(:h2, @title, class: H_CLASS) if @title.present?
			@objects.each { |obj| content << accordion_object(obj) }
			content << content_tag(:div, @tail, class: T_CLASS) if @tail.present?
			content_tag(:div, id: "accordion-collapse") { safe_join(content) }   # ← sin controller
		end

		def form=(formobj)
			@form = formobj
			@objects.each do |obj|
				c = obj[:content]
				c.form = formobj if c.respond_to?(:form=)
			end
		end

		private

		def accordion_object(obj)
			mode = (obj[:fit] || @mode).to_sym
			content_tag(:details,
				id: obj[:body_id],
				name: "accordion-group",
				class: "group border-b border-gray-200",
				open: false) do
				summary_tag(obj) + body_tag(obj, mode)
			end
		end

		def summary_tag(obj)
			content_tag(:summary,
				class: "#{I_CLASS} accordion-summary list-none cursor-pointer " \
							"[&::-webkit-details-marker]:hidden " \
							"group-open:bg-indigo-900 group-open:text-gray-200 " \
							"group-open:shadow-sm") do
				content_tag(:span, obj[:head]) + chevron_svg
			end
		end

		def chevron_svg
			content_tag(:svg, nil, data: { accordion_icon: true },
				class: "w-6 h-6 shrink-0 transition-transform duration-200 group-open:rotate-180",
				fill: "currentColor", viewBox: "0 0 20 20", xmlns: "http://www.w3.org/2000/svg") do
					tag(:path, fill_rule: "evenodd",
							d: "M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z",
							clip_rule: "evenodd")
			end
		end

		def body_tag(obj, mode)
			classes = BODY_CLASS.fetch(mode)
			if mode == :scale
				content_tag(:div, class: classes, data: { controller: "fit-content" }) do
					content_tag(:div, class: "w-full", data: { fit_content_target: "scalable" }) do
						body_content(obj)
					end
				end
			else
				content_tag(:div, class: classes) { body_content(obj) }
			end
		end

		def body_content(obj)
			if obj[:content].class == FieldsComponent
				render(obj[:content])
			else
				obj[:content]
			end
		end
end
