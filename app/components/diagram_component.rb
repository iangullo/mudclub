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
	SHOW_SVG_CLASS = "w-full max-w-full block overflow-hidden"
	EDIT_SVG_CLASS = "max-w-[90vw] max-h-[80vh] w-full overflow-hidden border"

	attr_writer :form # Allows assigning the form after initialization

	def initialize(sport: "basketball", canvas:, svgdata:, css: nil, form: nil)
		@id       = "diagram-#{SecureRandom.hex(4)}"
		@sport    = sport
		@canvas   = canvas.presence
		@svgdata  = svgdata.presence || {}
		@svgclass = css.presence || SHOW_SVG_CLASS
		@form     = form
	end

	def call
		vb = get_viewbox

		svg_tag = content_tag :svg,
			svg_body.html_safe,
			class: @svgclass,
			xmlns: "http://www.w3.org/2000/svg",
			viewBox: "#{vb["x"]} #{vb["y"]} #{vb["width"]} #{vb["height"]}",
			preserveAspectRatio: "xMidYMid meet",
			width: "100%",
			height: "100%",
			data: svg_data_attributes

		if editor?
			content_tag :div, data: { controller: "diagram-editor" } do
				safe_join(
					[editor_buttons_container,
					content_tag(:div, id: @id, class: EDIT_SVG_CLASS) {	svg_tag },
					hidden_field_for_svgdata
				])
			end
		else
			svg_tag
		end
	end

	private
		# unified button creator for editor actions
		def action_button(btn, line_shape: nil, line_style: nil, line_ending: nil)
			if btn[:object] == "delete"
				title = I18n.t("action.remove")
				icon  = "delete.svg"
				bcls  = "p-1 border rounded hover:bg-red-100 disabled:opacity-50 disabled:bg-gray-200 disabled:cursor-not-allowed"
				data  =  {action: "click->diagram-editor##{btn[:action]}", diagram_editor_target: "deleteButton"}
			else
				title = I18n.t("sport.#{@sport}.objects.#{btn[:object]}")
				icon  = "sport/#{@sport}/#{btn[:object]}.svg"
				bcls  = "p-1 border rounded hover:bg-gray-100"
				data  =  {action: "click->diagram-editor##{btn[:action]}", line_shape:, line_style:, line_ending: }
			end
			ButtonComponent.new(kind: :stimulus, icon:, title:, class: bcls, data:)
		end

		def canvas_url
			if @canvas.present?
				return @canvas if @canvas =~ /\A(http|\/rails\/active_storage)/
				return helpers.asset_path(@canvas)
			end
			helpers.asset_path("sport/#{@sport}/court_full.svg")
		end

		def editor?
			@form.present?
		end

		def editor_buttons
			res = [
				{ action: 'addCoach', object: 'coach' },
				{ action: 'addAttacker', object: 'attacker' },
				{ action: 'addDefender', object: 'defender' },
				{ action: 'addBall', object: 'ball' },
				{ action: 'addCone', object: 'cone' },
				{ action: 'startDrawing', object: 'shot', line_shape: "straight", line_style: "double", line_ending: "arrow" },
				{ action: 'startDrawing', object: 'pass', line_shape: "straight", line_style: "dashed", line_ending: "arrow" },
				{ action: 'startDrawing', object: 'move', line_shape: "bezier", line_style: "solid", line_ending: "arrow" },
				{ action: 'startDrawing', object: 'dribble', line_shape: "bezier", line_style: "wavy", line_ending: "arrow" },
				{ action: 'deleteSelected', object: 'delete' },
			].map do |btn|
				render action_button(btn)
			end
		end

		def editor_buttons_container
			content_tag :div, class: "m-2 inline-flex flex-shrink-0" do
				safe_join(editor_buttons)
			end
		end

		def get_viewbox
			@svgdata["viewBox"] || { "x" => 0, "y" => 0, "width" => 1000, "height" => 800 }
		end

		def hidden_field_for_svgdata
			return "" unless @form
			@form.hidden_field :svgdata, value: @svgdata, data: { "diagram-editor-target": "output" }
		end

		def render_canvas
			return unless @canvas.present?
			%(<image href="#{ERB::Util.html_escape(canvas_url)}"
					x="0" y="0" width="100%" height="100%"
					preserveAspectRatio="xMidYMid meet"
					style="pointer-events: none; user-select: none;"/>)
		end

		def render_element(item)
			transform = item["transform"] || ""
			x = item["x"]
			y = item["y"]
			case item["type"]
			when "object"
				label = ERB::Util.html_escape(item["label"] || "")
				role = ERB::Util.html_escape(item["role"] || "")
				content = item["content"] || ""
		
				<<~HTML
					<g data-type="object" data-role="#{role}" data-label="#{label}" transform="#{transform}" x="#{x}" y="#{y}">
						#{content}
					</g>
				HTML
			when "path"
				style = ERB::Util.html_escape(item["style"] || "solid")
				stroke = ERB::Util.html_escape(item["stroke"] || "black")
				ending = ERB::Util.html_escape(item["ending"] || "")
				points = ERB::Util.html_escape(item["points"].to_json)
				d = generate_path_d_from_points(item["points"] || [], item["style"] || "solid")
		
				<<~HTML
					<g data-type="path" transform="#{transform}">
						<path d="#{d}"
									data-type="bezier"
									data-style="#{style}"
									data-ending="#{ending}"
									data-stroke="#{stroke}"
									data-points='#{points}'
									fill="none"
									stroke="#{stroke}" />
					</g>
				HTML
		
			when "group"
				children = (item["elements"] || []).map { |child| render_element(child) }.join
		
				<<~HTML
					<g transform="#{transform}">
						#{children}
					</g>
				HTML
		
			else
				Rails.logger.warn("DiagramRenderer: Unknown element type #{item["type"]}")
				""
			end
		rescue => e
			Rails.logger.warn("DiagramRenderer error: #{e.message}")
			""
		end		

		def svg_attributes(hash)
			hash.map { |k, v| "#{k}='#{v}'" }.join(" ")
		end

		def svg_body
			canvas_img = render_canvas
			elements = (@svgdata["elements"] || []).map { |item| render_element(item) }.join
			[canvas_img, elements].compact.join
		end

		def svg_data_attributes
			return {} unless editor?
			{
				"diagram-editor-target": "canvas",
				"diagram-editor-svgdata-value": ERB::Util.json_escape(@svgdata.to_json),
				"diagram-editor-sport-value": @sport
			}
		end
end
