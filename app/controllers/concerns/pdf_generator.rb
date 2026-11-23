# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
# handle creation of PDFs -relies on PrawnPDF
module PdfGenerator
	GUTTER        = 10 # Adjust these as needed
	HEADER_HEIGHT = 40
	FOOTER_HEIGHT = 40
	FONT_SIZE     = 10
	PIC_HEIGHT    = 220

	# Initialize variables for document, header and footer
	# header: [array of field component definitions]
	# footer: text to be placed on left side of the footer
	def pdf_create(header: nil, footer: nil, page_size: "A5", page_layout: :portrait, full_width: nil)
		@pdf    = Prawn::Document.new(page_size:, page_layout:, margin: 20)
		@header = set_header(header, full_width)	# prepare the page header content
		@footer = footer
		@content_height = @pdf.bounds.height - @header_height - FOOTER_HEIGHT
		setup_new_page
		@pdf
	end

	# def a pdf label
	def pdf_label_text(label:, text: nil)
		if label.present?
			label    += ":" if text.present?
			label_w   = @pdf.width_of("<b>#{label}</b>", inline_format: true)
			@pdf.text_box "<b>#{label}</b>", inline_format: true, at: [ @pdf.bounds.left, @pdf.cursor ]
		else
			label_w = 0
		end
		row_h = label_row_height(label, text, label_w)
		if text.present?
			@pdf.text_box text.to_s, at: [ @pdf.bounds.left + label_w + 5, @pdf.cursor ],
															width: @pdf.bounds.width - label_w - 5, height: @pdf.cursor
		end
		start_new_page_if_needed(row_h)
		@pdf.y -= (row_h + 3)
	end

	# add a new page to the document
	def pdf_new_page
		@pdf.start_new_page
		setup_new_page
	end

	# Render rich text in PDF. Handles ActionText attachments (blobs and
	# RemoteImages) plus regular HTML nodes. One dispatch point for
	# attachment types; one for HTML.
	def pdf_rich_text(rich_text)
		return if rich_text&.body.blank?

		@pdf.y     -= 3
		rich_noko   = Nokogiri::HTML.fragment(rich_text.body.to_html)
		attachments = rich_text.body.attachments.to_a
		ndx         = 0

		rich_noko.children.each do |node|
			if node.name == "div"
				node.children.each do |child|
					if child.name == "action-text-attachment"
						render_attachment(attachments[ndx], caption: child[:caption])
						ndx += 1
					else
						render_rich_node(child)
					end
				end
			else
				render_rich_node(node)
			end
		end
	end

	# Draw a horizontal line to separate sections
	def pdf_separator_line(style: "single")
		@pdf.stroke_color "000000" # Set line color to black
		case style
		when "empty"; lines = 0; @pdf.move_down(10)
		when "single"; lines = 1
		when "double"; lines = 2
		end
		lines.times do
			@pdf.stroke_horizontal_rule
			@pdf.move_down 5 # Adjust the space between sections as needed
		end
	end

	def pdf_subtitle(subtitle)
		start_new_page_if_needed(30)
		pdf_separator_line
		pdf_label_text(label: subtitle)
		pdf_separator_line
	end

	private
		# Resolve an ActionText attachable to a PNG-ready IO. Returns nil if
		# it can't be rendered — caller silently skips.
		def attachable_to_png(attachable)
			case attachable
			when ActiveStorage::Blob
				attachable.image? ? image_to_png(StringIO.new(attachable.download)) : nil
			when ActiveStorage::Attachment
				attachable_to_png(attachable.blob)
			when ActionText::Attachables::RemoteImage
				download_remote_to_png(attachable.url)
			else
				Rails.logger.info("[PdfGenerator] Skipping attachable: #{attachable.class}")
				nil
			end
		rescue StandardError => e
			Rails.logger.warn("[PdfGenerator] render #{attachable.class} failed: #{e.class}: #{e.message}")
			nil
		end

		# A row is a flat list of Prawn cells. Each field contributes zero or
		# more cells; :symbol and unresolvable icons contribute zero so that
		# alignment survives.
		def build_row(items)
			items.flat_map { |item| cells_for(item) }
		end

		def cells_for(item)
			align = (item[:align] || :left).to_sym
			base  = { content: nil, border_widths: [ 0, 0, 0, 0 ], padding: [ 0, 0, 0, 0 ] }
			span  = item[:cols].to_i
			rspan = item[:rows].to_i
			base[:rowspan] = rspan if rspan > 1

			case item[:kind].to_s
			when "gap"
				cell = base.merge(content: " ")
				cell[:colspan] = span if span > 1
				[ cell ]

			when "icon", "header_icon", "header-icon"
				cell = icon_cell(base, item[:value], small: item[:kind].to_s == "icon", align: (item[:align] || :right).to_sym)
				cell.first[:colspan] = span if span > 1 && cell.any?
				cell

			when "symbol"
				png  = resolve_symbol_png(item[:symbol], size: 16)
				cell = if png
					base.merge(content: nil, image: png, fit: [ 16, 16 ],
										position: (item[:align] || :right).to_sym, vposition: :center, padding: [ 0, 0, 0, 5 ])
				else
					base.merge(content: " ")
				end
				cell[:colspan] = span if span > 1
				[ cell ]

			when "icon_label"
				lbl_cell = base.merge(content: item[:label].to_s, align:,
															padding: [ 0, 0, 0, 5 ], size: 10, valign: :center)
				lbl_cell[:colspan] = span - 1 if span > 2
				icon_cell(base, item[:icon], small: true, align: :right) + [ lbl_cell ]

			when "title"
				cell = base.merge(
					content:    item[:value].to_s,
					align:,
					font_style: :bold,
					padding:    [ 0, 0, 0, 10 ],
					size:       12,
					text_color: "000080"
				)
				cell[:colspan] = span if span > 1
				[ cell ]

			when "subtitle"
				cell = base.merge(
					content:    item[:value].to_s,
					align:,
					font_style: :bold,
					padding:    [ 0, 0, 0, 10 ],
					size:       10,
					valign:     :top
				)
				cell[:colspan] = span if span > 1
				[ cell ]

			else
				v = item[:value]
				return [] if v.nil?

				cell = base.merge(content: v.to_s, align:,
													padding: [ 0, 0, 0, align == :right ? 2 : 5 ], size: 10, valign: :top)
				cell[:colspan] = span if span > 1
				[ cell ]
			end
		end


		# Allocate bounds.width proportionally across columns based on the widest
		# cell that appears in each column. Icons/symbols/gaps get a narrow weight;
		# labels/texts get a flexible weight.
		def compute_column_widths(header, _max_rows)
			expanded = header.map do |row|
				row.flat_map do |item|
					if item[:kind].to_s == "icon_label"
						span = [ item[:cols].to_i - 1, 1 ].max
						[ { kind: "icon", cols: 1 }, { kind: "label", cols: span } ]
					else
						[ item ]
					end
				end
			end

			rowspans = Hash.new(0) # col_index => remaining rows occupied from above
			weights  = []

			expanded.each do |row|
				col = 0
				row.each do |item|
					col += 1 while rowspans[col] > 0

					cspan = [ item[:cols].to_i, 1 ].max
					rspan = [ item[:rows].to_i, 1 ].max
					w = case item[:kind].to_s
					when "header-icon", "header_icon" then 0.65
					when "icon", "symbol" then 0.35
					when "gap" then 0.5
					when "label", "text", "string", "subtitle", "title"
						item[:align]&.to_sym == :right ? 1.6 : 3.5
					else 1.5
					end

					cspan.times do |i|
						weights[col + i] = [ weights[col + i].to_f, w ].max
						rowspans[col + i] = rspan if rspan > 1
					end
					col += cspan
				end
				rowspans.transform_values! { |v| [ v - 1, 0 ].max }
			end

			return nil if weights.empty?

			total = weights.sum
			weights.map { |w| @header_width * w / total }
		end

		def download_remote_to_png(url, read_timeout: 5, open_timeout: 3, max_bytes: 10.megabytes)
			require "open-uri"
			io   = URI.open(url, read_timeout:, open_timeout:)
			data = io.read(max_bytes + 1)
			raise "Remote image too large (#{url})" if data.bytesize > max_bytes
			image_to_png(StringIO.new(data))
		end

		# Check if there's enough space left on the current page
		def enough_space_for_content?(height)
			@pdf.cursor - height >= FOOTER_HEIGHT
		end

		def icon_cell(base, value, small:, align: :right)
			png = resolve_icon(value)
			return [] unless png

			[ base.merge(
					content:   nil,
					image:     png,
					fit:       small ? [ 16, 16 ] : [ 32, 32 ],
					padding:   [ 0, 4, 0, 0 ],
					position:  align,
					vposition: :center
				) ]
		end

		# Convert an arbitrary image IO/path to a PNG-ready IO.
		# Detects SVG by content, routes to rsvg-convert (preferred) or Vips.
		def image_to_png(source, max_dim: 512)
			bytes = read_bytes(source)
			return nil if bytes.nil? || bytes.empty?

			bytes.include?("<svg") ? svg_to_png(bytes, height: max_dim) : vips_to_png(bytes, max_dim:)
		rescue StandardError => e
			Rails.logger.warn("[PdfGenerator] image_to_png failed: #{e.class}: #{e.message}")
			nil
		end

		# Used by pdf_label_text, which passes [label, text, label_width].
		def label_row_height(label, text, label_width)
			label_height = @pdf.height_of("<b>#{label}:</b>", inline_format: true)
			text_height  =
				if text.is_a?(Array)
					text.sum { |line| @pdf.height_of(line.to_s, width: @pdf.bounds.width - label_width.to_i) }
				else
					@pdf.height_of(text.to_s, width: @pdf.bounds.width - label_width.to_i)
				end
			[ label_height, text_height ].max
		end

		# Used by render_rich_node, which passes a Nokogiri node or a string.
		def node_height(node)
			@pdf.height_of(node.try(:html) || node.try(:to_s), width: @pdf.bounds.width) + 5
		end

		def read_bytes(source)
			case source
			when String   then File.binread(source)
			when Pathname then File.binread(source.to_s)
			else
				source.rewind if source.respond_to?(:rewind)
				source.read
			end
		end

		# render an attachment as a PDF element
		def render_attachment(attachment, caption: nil)
			return unless attachment

			png = attachable_to_png(attachment.attachable)
			return unless png

			png = rotate_portrait(png)
			start_new_page_if_needed(PIC_HEIGHT + 12)
			@pdf.image png, fit: [ @pdf.bounds.width - 2 * GUTTER, PIC_HEIGHT ], position: :center
			@pdf.text(caption, size: 10, styles: [ :italic ], align: :center) if caption
		end

		# render the pdf table as a header
		def render_header
			return if @header.blank?

			opts = { width: @header_width }.compact
			opts[:column_widths] = @header_column_widths if @header_column_widths
			@pdf.table(@header, **opts)
		end

		# render footers for pdf pages
		def render_footer
			# Add page numbers and drill author to footer
			if @footer
				@pdf.bounding_box([ @pdf.bounds.left + 10, @pdf.bounds.bottom + 20 ], width: @pdf.bounds.width) do
					@pdf.fill_color = "8b8680"	# mid gray font
					@pdf.text @footer, size: 10
				end
			end
			@pdf.bounding_box([ @pdf.bounds.right - 20, @pdf.bounds.bottom + 20 ], width: @pdf.bounds.width) do
				@pdf.fill_color = "8b8680"	# mid gray font
				@pdf.number_pages "# <page>", size: 10
			end
		end

		def render_rich_node(node)
			start_new_page_if_needed(node_height(node))
			PrawnHtml.append_html(@pdf, node&.to_html)
		end

		def resolve_icon(value)
			case value
			when ActiveStorage::Attached::One
				# value.attached? ? attachable_to_png(value.blob) : nil
				unless value.attached?
					Rails.logger.warn("[PdfGenerator] icon: not attached (name=#{value.name}, record=#{value.record.class})")
					return nil
				end
		    blob = value.blob
				Rails.logger.info("[PdfGenerator] icon blob: content_type=#{blob.content_type} size=#{blob.byte_size} image?=#{blob.image?} filename=#{blob.filename}")
				attachable_to_png(blob)
			when ActiveStorage::Blob
				attachable_to_png(value)
			when String, Pathname
				path = Rails.root.join("app", "assets", "images", value.to_s)
				path.exist? ? image_to_png(path) : nil
			end
		rescue StandardError => e
			Rails.logger.warn("[PdfGenerator] header icon (#{value.class}): #{e.class}: #{e.message}")
			nil
		end

		def resolve_symbol_png(spec, size: 16)
			spec = { concept: spec } if spec.is_a?(Symbol) || spec.is_a?(String)
			return nil if spec.blank?

			concept   = spec[:concept]  || spec["concept"]
			options   = spec[:options]  || spec["options"] || {}
			return nil unless concept

			namespace = options[:namespace] || "common"
			type      = (options[:type]     || :icon).to_sym
			variant   = options[:variant]   || "default"

			node = SymbolRegistry.fetch(namespace:, type:, concept:, variant:)
			return nil unless node.is_a?(Nokogiri::XML::Node)

			svg = symbol_node_to_svg(node, size:)
			return nil if svg.blank?

			svg_to_png(svg, height: size * 4)
		rescue StandardError => e
			Rails.logger.warn("[PdfGenerator] resolve_symbol_png(#{spec.inspect}): #{e.class}: #{e.message}")
			nil
		end

		def rotate_portrait(png_io)
			img = Vips::Image.new_from_buffer(png_io.read, "")
			return StringIO.new(img.write_to_buffer(".png")) if img.width >= img.height
			img = img.rot("d270")
			StringIO.new(img.write_to_buffer(".png"))
		end

		def rsvg_to_png(bytes, height:)
			require "open3"
			out, err, status = Open3.capture3(
				"rsvg-convert", "--format=png", "--height=#{height}", "-",
				stdin_data: bytes
			)
			return StringIO.new(out) if status.success?

			Rails.logger.warn("[PdfGenerator] rsvg-convert: #{err}")
			nil
		rescue Errno::ENOENT
			Rails.logger.warn("[PdfGenerator] rsvg-convert not installed")
			nil
		end

		# header of a pdf page. basically expecting 2 rows
		# [icon] - [title, some optional fields]
		#        - [subttle, some additonal optonal fields]
		def set_header(header, full)
			return [] if header.blank?

			@header_width  = (full ? @pdf.bounds.width : nil)
			rows = header.map { |row| build_row(row) }.reject(&:empty?)
			return [] if rows.empty?

			if @header_width
				@header_column_widths = compute_column_widths(header, rows.size)
			end

			opts = { width: @header_width }.compact
			opts[:column_widths] = @header_column_widths if @header_column_widths
			@header_height = @pdf.make_table(rows, **opts).height + 6

			rows
		end

		# setup header/footer && place curser where appropriate
		def setup_new_page
			render_header if @header
			render_footer if @footer
			@pdf.fill_color = "404040"	# back to regular color: black
			@pdf.y          = @pdf.bounds.top - (@header.present? ? @header_height : GUTTER) # Move cursor below the header
			@pdf.font_size(FONT_SIZE)
		end

		# Start a new page if there's not enough space left
		def start_new_page_if_needed(height)
			pdf_new_page unless enough_space_for_content?(height)
		end

		# SVG → PNG via rsvg-convert (librsvg CLI) with Vips fallback.
		def svg_to_png(bytes, height: 128)
			png = rsvg_to_png(bytes, height:)
			return png if png

			# Fallback — Vips can read SVG only if librsvg delegate is compiled in.
			image = Vips::Image.new_from_buffer(bytes, "")
			image = image.thumbnail_image(height * 2) if image.width > height * 2 || image.height > height * 2
			StringIO.new(image.write_to_buffer(".png"))
		rescue StandardError => e
			Rails.logger.error("[PdfGenerator] SVG conversion impossible: #{e.class}: #{e.message}")
			nil
		end

		# Wrap a Nokogiri <symbol> node in a standalone <svg> document so
		# rsvg-convert / Vips can rasterize it. The registry has already
		# resolved any <use> references, so the children are self-contained.
		def symbol_node_to_svg(node, size:)
			viewbox = node["viewBox"] || "0 0 24 24"
			inner   = node.children.map(&:to_xml).join
			px      = size * 4

			%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="#{viewbox}" width="#{px}" height="#{px}" preserveAspectRatio="xMidYMid meet">#{inner}</svg>)
		end

		# Direct Vips conversion. Input is raw bytes; output is a StringIO of PNG.
		# Shrinks large sources — a 6.8 MB avatar for a 32 px header cell
		# bloats the PDF needlessly, and thumbnail_image() uses shrink-on-load.
		def vips_to_png(bytes, max_dim: 512)
			image = Vips::Image.new_from_buffer(bytes, "")
			image = image.thumbnail_image(max_dim) if image.width > max_dim || image.height > max_dim
			StringIO.new(image.write_to_buffer(".png"))
		rescue StandardError => e
			Rails.logger.warn("[PdfGenerator] vips_to_png failed: #{e.class}: #{e.message}")
			nil
		end
end
