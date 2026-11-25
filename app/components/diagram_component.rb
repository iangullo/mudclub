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

# ViewComponent to render SVG diagrams for drill steps.
# Can act as either display or editor depending on the presence of a form object.
class DiagramComponent < ApplicationComponent
	MARKER_SIZE   = 5
	MARKER_DOUBLE = MARKER_SIZE * 2
	MARKER_HALF   = MARKER_SIZE / 2
	SYMBOL_SIZE   = 33.87
	SHOW_SVG_CLASS = "block w-full h-auto"
	EDIT_SVG_CLASS = "block w-full h-full"
	EDIT_CONTAINER_CLASS    = "w-full overflow-hidden border rounded"
	DEFAULT_VIEW_MAX_HEIGHT = "80svh"
	DEFAULT_EDIT_MAX_HEIGHT = "65svh"
	EDITOR_BUTTONS = [
		{ action: "addAttacker", object: "attacker", options: { label: "?" } },
		{ action: "addDefender", object: "defender", options: { label: "n" } },
		{ action: "addBall", object: "ball" },
		{ action: "addCone", object: "cone" },
		{ action: "addCoach", object: "coach" },
		{ action: "startDrawing", object: "shot", path: { curve: false, style: "double", ending: "arrow" } },
		{ action: "startDrawing", object: "pass", path: { curve: false, style: "dashed", ending: "arrow" } },
		{ action: "startDrawing", object: "dribble", path: { curve: true, style: "wavy", ending: "arrow" } },
		{ action: "startDrawing", object: "handoff", path: { curve: false, style: "double", ending: "none" } },
		{ action: "startDrawing", object: "move", path: { curve: true, style: "solid", ending: "arrow" } },
		{ action: "startDrawing", object: "pick", path: { curve: true, style: "solid", ending: "tee" } },
		{ action: "showColorMenu", object: "color" },
		{ action: "deleteSelected", object: "delete" }
	].freeze

	attr_writer :form # Allows assigning the form after initialization

	def initialize(sport: "basketball", court:, svgdata:, css: nil, form: nil, max_height: nil)
		@id         = "diagram-#{SecureRandom.hex(4)}"
		@sport      = Sport.fetch(sport)
		@css        = css
		@court      = { name: court, sport: sport }
		@svgdata    = svgdata.presence || {}
		@max_height = max_height
		@form       = form
	end

	def call
		svg_content = generate_diagram_content

		if editor?
			edit_h = @max_height.presence || DEFAULT_EDIT_MAX_HEIGHT
			safe_join(
				[
					editor_buttons_container,
					content_tag(:div,
						id: "#{@id}-container",
						class: EDIT_CONTAINER_CLASS,
						style: ("height: #{edit_h}; max-height: #{edit_h};")
					) { svg_content },
					hidden_editor_fields,
					color_menu	# contextual color selector
				]
			)
		else
			content_tag(:div,
				class: "diagram-container w-full max-w-full",
				data: { controller: "diagram-renderer",
				diagram_renderer_svgdata_value: @svgdata }) do
					svg_content.html_safe
			end
		end
	end

	private
		# unified button creator for editor actions
		def action_button(btn)
			base = "m-1 rounded hover:bg-"

			if btn[:object] == "delete"
				title  = UI::Action.act(:remove)
				symbol = { concept: "delete", options: { type: :button } }
				bcls   = "#{base}red-100"
				data   = { action: "click->diagram-editor##{btn[:action]}", button_target: true }
			elsif btn[:object] == "color"
				title  = UI::Color.label(:plural)
				symbol = { concept: "color", options: { type: :button } }
				bcls   = "#{base}gray-100"
				data   = { action: "click->diagram-editor##{btn[:action]}", button_target: true }
			else
				symbol_id = [ @sport.name, "object", btn[:object], "default" ].join(".")
				title     = @sport.t_path(:objects, :values, btn[:object])
				options   = { namespace: @sport.name, type: :object }
				options.merge!(btn[:options]) if btn[:options]
				symbol    = { concept: btn[:object], options: }
				bcls      = "#{base}gray-100"
				data      = { action: "click->diagram-editor##{btn[:action]}", symbol_id: }
				data.merge!(btn[:path]) if btn[:path]
			end

			data[:diagram_editor_target] = "#{btn[:object]}Button"
			ButtonComponent.new(kind: :stimulus, symbol:, title:, d_class: bcls, data:)
		end

		def color_menu
			content_tag(:div, id: "color-menu",
										class: "hidden absolute bg-white border border-gray-300 rounded shadow-lg z-50 p-2",
										data: { diagram_editor_target: "colorMenu" }) do
				safe_join([
					content_tag(:div, UI::Color.label(:plural), class: "font-bold mb-2"),
					content_tag(:div, class: "color-palette grid grid-cols-4 gap-1") do
						safe_join([
							color_option("#000000", "black"),
							color_option("#FF0000", "red"),
							color_option("#0000FF", "blue"),
							color_option("#008000", "green"),
							color_option("#E86100", "orange"),
							color_option("#800080", "purple")
						])
					end
				])
			end
		end

		def color_option(color_code, color_name)
			content_tag(:button,
									"",
									class: "w-6 h-6 rounded border border-gray-300",
									style: "background-color: #{color_code}",
									title: UI::Color.val(color_name),
									data: {
										action: "click->diagram-editor#applyColor",
										color: color_code
									})
		end

		def editor?
			@form.present?
		end

		def editor_buttons
			EDITOR_BUTTONS.map { |btn| render action_button(btn) }
		end

		def editor_buttons_container
			content_tag :div, id: "diagram-editor-buttons", class: "flex-shrink-0 inline-flex flex-wrap m-1" do
				safe_join(editor_buttons)
			end
		end

		def generate_diagram_content
			svg_start = safe_join([ render_symbol_defs, render_court ])
			svg_attrs = {
				class:   svg_css,             # editor → h-full, viewer → h-auto
				id:      @id,
				height:  "100%",
				width:   "100%",
				preserveAspectRatio: "xMidYMid meet",
				viewBox: "#{@viewbox[:x]} #{@viewbox[:y]} #{@viewbox[:width]} #{@viewbox[:height]}",
				xmlns: "http://www.w3.org/2000/svg",
				'xmlns:xlink': "http://www.w3.org/1999/xlink",
				data: svg_data_attributes
			}
			svg_attrs[:style] = svg_style if svg_style

			content_tag(:div, class: "diagram-container h-full w-full", data: { loaded: "false" }) do
				content_tag(:svg, svg_start.html_safe, svg_attrs)
			end
		end

		def svg_css
			editor? ? EDIT_SVG_CLASS : show_css
		end

		# Cap the rendered diagram so it never exceeds viewport height on mobile.
		# `svh` accounts for mobile browser chrome; `preserveAspectRatio="xMidYMid meet"`
		# letterboxes the diagram instead of clipping it.
		def svg_style
			return nil if editor?
			max_h = @max_height.presence || DEFAULT_VIEW_MAX_HEIGHT
			"max-height: #{max_h};"
		end

		def get_viewbox(court)
			@viewbox || @svgdata["viewBox"] || { x: 0, y: 0, width: 1000, height: 800 }
		end

		def hidden_editor_fields
			return nil unless @form

			svgdata = (@svgdata || {
				paths: [], symbols: [], "viewBox": { "width" => 1000, "height" => 600 } # Default values
			}).to_json

			@form.hidden_field(:svgdata, value: svgdata, data: { diagram_editor_target: "svgdata" })
		end

		def render_court
			symbol = @court[:name]
			namespace = @court[:sport]
			data = editor? ? { diagram_editor_target: "court" } : { diagram_renderer_target: "court" }
			court = SymbolComponent.new(symbol, namespace:, type: :court, css: @css, group: true, data:)
			@viewbox = court.view_box
			render court
		end

		# Update the render_defs method to include symbols
		def render_symbol_defs
			content_tag(:defs) do
				safe_join([
					symbol_definitions  # Add symbol definitions here
				])
			end
		end

		def show_css
			@css.presence || SHOW_SVG_CLASS
		end

		def show_style
			return nil unless @max_height.present?
			"max-height: #{@max_height};"
		end

		def svg_data_attributes
			if editor?
				{ diagram_editor_target: "diagram" }
			else
				{ diagram_renderer_target: "diagram" }
			end
		end

		# Add this method to generate symbol definitions
		def symbol_definitions
			# Get unique symbol IDs from "add" action buttons
			symbol_ids = EDITOR_BUTTONS.select { |btn|
				btn[:action].start_with?("add") && btn[:object].present?
			}.map { |btn| btn[:object] }.uniq

			safe_join(symbol_ids.map do |symbol_id|
				# Render each symbol as a symbol definition
				symbol = SymbolComponent.new(symbol_id, namespace: @sport.name, type: :object)
				content_tag(:symbol, render(symbol),
										id: symbol.full_id,
										viewBox: "0 0 #{SYMBOL_SIZE} #{SYMBOL_SIZE}")
			end)
		end
end
