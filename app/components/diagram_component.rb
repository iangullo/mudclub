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

# ViewComponent to render SVG diagrams for drill steps.
# Can act as either display or editor depending on the presence of a form object.
class DiagramComponent < ApplicationComponent
	SHOW_SVG_CLASS = "w-full h-full block overflow-auto"
	EDIT_SVG_CLASS = "w-full h-full border"
	EDITOR_BUTTONS = [
		{ action: 'addCoach', object: 'coach' },
		{ action: 'addAttacker', object: 'attacker' },
		{ action: 'addDefender', object: 'defender' },
		{ action: 'addBall', object: 'ball' },
		{ action: 'addCone', object: 'cone' },
		{ action: 'startDrawing', object: 'shot', path: {curved: false, stroke: "double", ending: "arrow"} },
		{ action: 'startDrawing', object: 'pass', path: {curved: false, stroke: "dashed", ending: "arrow"} },
		{ action: 'startDrawing', object: 'move', path: {curved: true, stroke: "solid", ending: "arrow"} },
		{ action: 'startDrawing', object: 'dribble', path: {curved: true, stroke: "wavy", ending: "arrow"} },
		{ action: 'deleteSelected', object: 'delete' }
	].freeze

	attr_writer :form # Allows assigning the form after initialization

	def initialize(sport: "basketball", court:, svgdata:, css: nil, form: nil)
		@id       = "diagram-#{SecureRandom.hex(4)}"
		@sport   = sport
		@css     = css.presence || SHOW_SVG_CLASS
		@court   = SymbolComponent.new(court, namespace: sport, type: :court, css:, group: true, data: {diagram_editor_target: "court"})
		@svgdata = svgdata.presence || {}
		@form    = form
	end
	
	def call
		vb = get_viewbox

		svg_tag = content_tag :svg,
			svg_body.html_safe,
			class: @css,
			xmlns: "http://www.w3.org/2000/svg",
			viewBox: "#{vb[:x]} #{vb[:y]} #{vb[:width]} #{vb[:height]}",
			preserveAspectRatio: "xMidYMid meet",
			width: "100%",
			height: "100%",
			data: svg_data_attributes

		if editor?
			content_tag :div, class: SHOW_SVG_CLASS, data: { controller: "diagram-editor" } do
				safe_join(
					[
						editor_buttons_container,
						content_tag(:div, class: EDIT_SVG_CLASS + " border rounded", id: @id) {svg_tag },
						hidden_field_for_svgdata
					]
				)
			end
		else
			svg_tag
		end
	end

	private
		# unified button creator for editor actions
		def action_button(btn, path: nil)
			if btn[:object] == "delete"
				title  = I18n.t("action.remove")
				symbol = {concept: "delete", options: {type: :button}}
				bcls   = "hover:bg-red-100 disabled:opacity-50 disabled:bg-gray-200 disabled:cursor-not-allowed"
				data   = { action: "click->diagram-editor##{btn[:action]}", disabled: false, diagram_editor_target: "deleteButton" }
			else
				title  = I18n.t("sport.#{@sport}.objects.#{btn[:object]}")
				symbol = {concept: btn[:object], options: {namespace: @sport, type: :object}}
				symbol_id = [@sport, "object", btn[:object], "default"].join(".")
				bcls   = "hover:bg-gray-100"
				data   = { action: "click->diagram-editor##{btn[:action]}", path:, symbol_id: }
			end
			bcls = "m-1 rounded #{bcls}"
			ButtonComponent.new(kind: :stimulus, symbol:, title:, d_class: bcls, data:)
		end

		def editor?
			@form.present?
		end

		def editor_buttons
			EDITOR_BUTTONS.map { |btn| render action_button(btn) }
		end

		def editor_buttons_container
			content_tag :div, id: "diagram-editor-buttons", class: "flex-shrink-0 inline-flex mb-2" do
				safe_join(editor_buttons)
			end
		end

		def generate_path_d_from_points(points, curved)
			return "" if points.empty?
			return "" unless points.all? { |pt| pt.is_a?(Array) && pt.size == 2 }

			if curved
				# Bezier path (simplified for now — can refine later)
				"M#{points[0][0]},#{points[0][1]} " +
					points[1..].map { |(x, y)| "S#{x},#{y}" }.join(" ")
			else
				"M" + points.map { |x, y| "#{x},#{y}" }.join(" L")
			end
		end

		def get_viewbox
			@court.view_box || svgdata["viewBox"] || { x: 0, y: 0, width: 1000, height: 800 }
		end

		def hidden_field_for_svgdata
			return "" unless @form
			@form.hidden_field :svgdata, value: @svgdata, data: { "diagram-editor-target": "svgdata" }
		end

		def render_court
			render(@court) if @court.present?
		end

		def render_svg_objects
			(@svgdata["objects"] || []).map do |obj|	# need to handle position on the diagram!!
				# Pass concept as the 3rd segment (concept) of the symbol_id, or fallback to nil
				symbol_id = safe_attr(obj, :symbol_id)
				concept = symbol_id&.split(".")[2] || safe_attr(obj, :concept)
				options = {	# Build options expected by SymbolComponent
					data: {
						id:        safe_attr(obj, :id),
						symbol_id: safe_attr(obj, :symbol_id),
						fill:      safe_attr(obj, :fill),
						label:     safe_attr(obj, :label),
						stroke:    safe_attr(obj, :stroke),
						text_color: safe_attr(obj, :textColor),
						transform: safe_attr(obj, :transform)
					}
				}
				render SymbolComponent.new(concept, **options)
			end
		end

		def render_svg_paths
			(@svgdata["paths"] || []).map do |path|
				stroke = path["stroke"] || "solid"
				color  = path["color"] || "#000000"
				ending = path["ending"]
				curved = path["curved"]
				points = path["points"] || []

				d = generate_path_d_from_points(points, curved)

				content_tag(:g, data: {
					type: "path",
					stroke: stroke,
					ending: ending,
					curved: curved,
					color: color,
					points: points.to_json
				}) do
					tag.path(
						d: d,
						stroke: color,
						fill: "none",
						data: {
							type: "bezier"
						}
					)
				end
			end
		end

		def svg_attributes(hash)
			hash.map { |k, v| "#{k}='#{v}'" }.join(" ")
		end

		def svg_body
			safe_join([
				render_court,
				render_svg_objects,
				render_svg_paths
			])
		end

		def svg_data_attributes
			return {} unless editor?
			{
				diagram_editor_target: "diagram",
				diagram_editor_svgdata_value: @svgdata.to_json,
			}
		end
end
