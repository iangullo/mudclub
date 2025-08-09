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
		@split = check_splits
		@many = @steps.count > 1
	end

	def call
		content_tag(:div, class: "responsive-steps space-y-2 md:space-y-4") do
			safe_join([
				render_header,
				@steps.map { |step| render_step(step) }
			])
		end
	end

	private

	def check_splits
		@steps.each { |step| return true if step.has_text?}
		return nil
	end

	def render_header
		content_tag(:div, class: "inline-flex font-semibold") do
			concat(I18n.t("step.#{@many ? 'many' : 'explanation'}"))
		end
	end

	def render_step(step)
		content_tag(:div, class: "step-container py-2 md:py-3") do
			safe_join([
				render_order(step),
				content_tag(:div, class: "step-content flex flex-col md:flex-row gap-3 md:gap-4") do
					safe_join([render_diagram(step), render_explanation(step)])
				end
			])
		end
	end

	def render_order(step)
		return unless @many
		content_tag(:div, step.order, class: "step-order")
	end

	def render_diagram(step)
		return unless step.has_image? || step.has_svg?
		content_tag(:div, class: "step-diagram flex justify-center max-w-full overflow-hidden") do
			if step.has_image?
				concat(render_image({value: step.diagram.attachment}))
			else
				DiagramComponent.new(
					sport: step.sport.name,
					court: @court,
					svgdata: step.svgdata
				).render_in(view_context)
			end
		end
	end

	def render_explanation(step)
		return unless step.has_text? || @split
		content_tag(:div, class: "step-explanation md:min-w-[50%]") do
			concat(step.explanation&.body&.to_s) if step.has_text?
		end
	end
end