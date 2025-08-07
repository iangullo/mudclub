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

# app/components/responsive_steps_component.rb
# ViewComponent to render drill steps.
class StepsComponent < ApplicationComponent
	def initialize(steps:, court:)
		@steps = steps.order(:order)
		@court = court
		@many = @steps.count > 1
	end

	def call
		content_tag(:div, class: "responsive-steps") do
			safe_join([
				render_header,
				@steps.map { |step| render_step(step) }
			])
		end
	end

	private

	def render_header
		content_tag(:div, class: "step-header") do
			FieldsComponent.new([
				[{kind: :label, value: I18n.t("step.#{@many ? 'many' : 'explanation'}"), cols: 3}],
				[{kind: :separator, cols: 3}]
			]).render_in(view_context)
		end
	end

	def render_step(step)
		content_tag(:div, class: "step-container") do
			render_order(step)
			content_tag(:div, class: "step-content") do
				safe_join([
					render_diagram(step),
					render_explanation(step),
					render_separator
				])
			end
		end
	end

	def render_order(step)
		return unless @many
		content_tag(:div, step.order, class: "step-order")
	end

	def render_diagram(step)
		return unless step.has_image? || step.has_svg?
		content_tag(:div, class: "step-diagram") do
			if step.has_image?
				FieldsComponent.new([[
					{kind: :image, value: step.diagram.attachment, i_class: "m-1"}
				]]).render_in(view_context)
			else
				FieldsComponent.new([[
					{kind: :diagram, court: @court, svgdata: step.svgdata, css: "m-1"}
				]]).render_in(view_context)
			end
		end
	end

	def render_explanation(step)
		return unless step.has_text?
		content_tag(:div, class: "step-explanation") do
			FieldsComponent.new([[
				{kind: :action_text, value: step.explanation&.body&.to_s, align: "top"}
			]]).render_in(view_context)
		end
	end

	def render_separator
		content_tag(:div, class: "step-separator") do
			FieldsComponent.new([[
				{kind: :separator, cols: 3}
			]]).render_in(view_context)
		end
	end
end