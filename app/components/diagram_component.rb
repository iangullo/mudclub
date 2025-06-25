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
	SYMBOL_SCALE   = 0.07
	SYMBOL_SIZE    = 33.87
	SHOW_SVG_CLASS = "w-full h-full block overflow-auto"
	EDIT_SVG_CLASS = "w-full h-full border"
	EDITOR_BUTTONS = [
		{ action: 'addAttacker', object: 'attacker', options: {label: "?"} },
		{ action: 'addDefender', object: 'defender', options: {label: "n"} },
		{ action: 'addBall', object: 'ball' },
		{ action: 'addCone', object: 'cone' },
		{ action: 'addCoach', object: 'coach' },
		{ action: 'startDrawing', object: 'move', path: {curve: true, style: "solid", ending: "arrow"} },
		{ action: 'startDrawing', object: 'dribble', path: {curve: true, style: "wavy", ending: "arrow"} },
		{ action: 'startDrawing', object: 'pass', path: {curve: false, style: "dashed", ending: "arrow"} },
		{ action: 'startDrawing', object: 'shot', path: {curve: false, style: "double", ending: "arrow"} },
		{ action: 'deleteSelected', object: 'delete' }
	].freeze

	attr_writer :form # Allows assigning the form after initialization

	def initialize(sport: "basketball", court:, svgdata:, css: nil, form: nil)
		@id       = "diagram-#{SecureRandom.hex(4)}"
		@sport   = sport
		@css     = css.presence || SHOW_SVG_CLASS
		@court   = SymbolComponent.new(court, namespace: sport, type: :court, css:, group: true, data: {diagram_editor_target: "court"})
		@viewbox = get_viewbox
		@symbolh = @viewbox[:height].to_i * SYMBOL_SCALE / SYMBOL_SIZE
		@svgdata = svgdata.presence || {}

		@form    = form
	end
	
	def call

		svg_tag = content_tag :svg,
			svg_body.html_safe,
			class: @css,
			xmlns: "http://www.w3.org/2000/svg",
			viewBox: "#{@viewbox[:x]} #{@viewbox[:y]} #{@viewbox[:width]} #{@viewbox[:height]}",
			preserveAspectRatio: "xMidYMid meet",
			width: "100%",
			height: "100%",
			data: svg_data_attributes

		if editor?
			safe_join(
				[
					editor_buttons_container,
					content_tag(:div, class: EDIT_SVG_CLASS + " border rounded", id: @id) { svg_tag },
					hidden_field_for_svgdata
				]
			)
		else
			safe_join([svg_tag, hidden_field_for_svgdata])
		end
	end

	private
		# unified button creator for editor actions
		def action_button(btn)
			if btn[:object] == "delete"
				title  = I18n.t("action.remove")
				symbol = {concept: "delete", options: {type: :button}}
				bcls   = "hover:bg-red-100 disabled:opacity-50 disabled:bg-gray-200 disabled:cursor-not-allowed"
				data   = { action: "click->diagram-editor##{btn[:action]}", disabled: false, diagram_editor_target: "deleteButton" }
			else
				symbol_id = [@sport, "object", btn[:object], "default"].join(".")
				title     = I18n.t("sport.#{@sport}.objects.#{btn[:object]}")
				options   = {namespace: @sport, type: :object}
				options.merge!(btn[:options]) if btn[:options]
				symbol = {concept: btn[:object], options:}
				bcls   = "hover:bg-gray-100"
				data   = { action: "click->diagram-editor##{btn[:action]}", symbol_id: }
				data.merge!(btn[:path]) if btn[:path]
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
			return nil unless @form

			svgdata = (@svgdata || {
				"paths" => [],
				"symbols" => [],
				"viewBox" => { "width" => 1000, "height" => 600 } # Default values
			}).to_json
			target = { diagram_editor_target: "svgdata" }
			@form.hidden_field :svgdata, value: svgdata, data: target
		end

		def render_court
			render(@court) if @court.present?
		end


		def render_paths
			pcnt = 0
			(@svgdata["paths"] || []).map do |path|
				id     = path["id"] || "path-#{pcnt}"
				pcnt  += 1
				curve  = path["curve"]
				ending = path["ending"]
				points = path["points"] || []
				stroke = path["stroke"] || "#000000"
				style  = path["style"] || "solid"

				d = generate_path_d_from_points(points, curved)

				content_tag(:g, data: {
					id:,
					type: "path",
					curve:,
					ending:,
					stroke:,
					style:,
					points: points.to_json
				}) do
					tag.path(
						d:,
						stroke:,
						fill: "none",
						data: {
							type: "bezier"
						}
					)
				end
			end
		end

		def render_symbol(scnt, symbol)
			id        = symbol["id"] || "sym-#{scnt}"
			symbol_id = symbol["symbol_id"] || "#{@sport}.object.#{symbol['kind']}.default"
			x = symbol["x"] || 0
			y = symbol["y"] || 0
			options = {
				namespace: @sport,
				type: :symbol,
				group: true,
				data: {
					id:,
					kind: symbol["kind"],
					symbol_id: symbol_id,
					x:,
					y:,
					fill: symbol["fill"],
					stroke: symbol["stroke"],
					text_color: symbol["textColor"],
					transform: "scale(#{@symbolh}) #{symbol['transform']}"
				}.compact
			}
		
			# Add visual attributes if present
			[:fill, :stroke, :label, :textColor].each do |attr|
				options[attr] = symbol[attr.to_s] if symbol[attr.to_s]
			end

			svg_wrapper(id, "symbol", render(SymbolComponent.new(symbol_id, **options)), x, y )
		end

		def render_symbols
			scount = 0
			(@svgdata["symbols"] || []).map do |symbol|
				scount += 1
				render_symbol(scount, symbol)
			end
		end

		def svg_attributes(hash)
			hash.map { |k, v| "#{k}='#{v}'" }.join(" ")
		end

		def svg_body
			safe_join([
				render_court,
				render_symbols,
				render_paths
			])
		end

		def svg_data_attributes
			{ diagram_editor_target: "diagram" }
		end

		def svg_wrapper(content_id, type, content_svg, x = 0, y = 0)
			content_tag(:g,
				content_svg,
				class: "wrapper",
				type:,
				draggable: "true",
				id: "#{content_id}-wrapper",
				transform: "translate(#{x},#{y})"
			)
		end
end
