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

# ViewCompoennt to manage diagram editor for Drill Steps.
class DiagramEditorComponent < ApplicationComponent
	def initialize(step, form: nil)
		@form       = form
		@step       = step
		@svg_data   = step.diagram_svg.presence
		@courts     = prepare_courts(step)
		@court      = step.court || :full # could also be stored
		@b_attacker = editor_button(icon: "attacker.svg", action: "click->diagram-editor#addAttacker")
		@b_defender = editor_button(icon: "defender.svg", action: "click->diagram-editor#addDefender")
		@b_ball     = editor_button(icon: "ball.svg", action: "click->diagram-editor#addBall")
		@b_cone     = editor_button(icon: "cone.svg", action: "click->diagram-editor#addCone")
	end

	def court_image(court)
		@courts[court.to_sym][:image]
	end

	def court_name(court)
		@courts[court.to_sym][:name]
	end

	def court_paths
		res = {}
		@courts.each_pair do |court, val|
			res[court] = image_path(val[:image])
		end
		res
	end

	def court_value(court)
		@courts[court.to_sym].key
	end

	# wrapper to define the component's @form - whe required.
	def form=(formobj)
		@form = formobj
	end

	def selected(court)
		if @court == court
			" selected='selected'"
		else
			""
		end
	end

	private
		def editor_button(icon:, action:)
			ButtonComponent.new(kind: :stimulus, title: action, icon:, data: {action:})
		end

		def prepare_courts(step)
			res = {}
			step.drill&.sport&.court_modes&.each do |court|
				res[court] = {name: step.drill.sport.court_name(court), image: step.drill.sport.court_image(court)}
			end
			res
		end
end
