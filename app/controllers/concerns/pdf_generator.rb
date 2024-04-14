# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
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
		return @pdf
	end

	# def a pdf label
	def pdf_label_text(label:, text: nil)
		if label.present?
			label += ":" if text.present?
			label_width  = @pdf.width_of("<b>#{label}</b>", inline_format: true)
			@pdf.text_box "<b>#{label}</b>", inline_format: true, at: [@pdf.bounds.left, @pdf.cursor]
		else
			label_width  = 0
		end
		label_height = content_height([label, text, label_width])
		if text.present?
			@pdf.text_box text.to_s, at: [@pdf.bounds.left + label_width + 5, @pdf.cursor], width: @pdf.bounds.width - label_width - 5, height: @pdf.cursor
		end
		start_new_page_if_needed(label_height) # Adjust the content height as needed
		@pdf.y -= (label_height + 3)
	end

	# add a new page to the document
	def pdf_new_page
		@pdf.start_new_page
		setup_new_page
	end	

	# Render rich text in PDF
	def pdf_rich_text(rich_text)
		@pdf.y -= 3
		rich_noko = Nokogiri::HTML.fragment(rich_text&.body&.to_html)
		ndx       = 0	# index for attachment keys
		att_keys  = rich_text&.body&.attachments&.pluck(:key) || []	# attachment Blob keys
		# Iterate through each embedded blob element
		rich_noko.children.each do |node|
			if node.name == 'div'
				node.children.each do |child|
					ndx += render_child(child, att_keys[ndx])
				end
			else
				start_new_page_if_needed(content_height(node))
				PrawnHtml.append_html(@pdf, node&.to_html)
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
		# Measure height of node content
		def content_height(node)
			if node.is_a?(Array)	# it is a table (label/text pair)
				label_height = @pdf.height_of("<b>#{node[0]}:</b>", inline_format: true)
				text_height  = 0
				width        = @pdf.bounds.width - node[2].to_i
				if node[1].is_a?(Array)
					node[1].each { |line| text_height += @pdf.height_of(line.to_s, width:) }
				else
					text_height = @pdf.height_of(node[1].to_s, width:)
				end
				[label_height, text_height].max
			else
				content = extract_content(node)
				@pdf.height_of(content, width: @pdf.bounds.width) + 5
			end
		end
		
		# Check if there's enough space left on the current page
		def enough_space_for_content?(content_height)
			@pdf.cursor - content_height >= FOOTER_HEIGHT
		end

		# Extract content from node
		def extract_content(node)
			node.try(:html) || node.try(:to_s)
		end

		# attempt to wraparound lines maintaining markup for text
		def extract_text_lines(html_content)
			# Parse HTML content using Nokogiri
			doc    = Nokogiri::HTML.fragment(html_content)
			lines  = []
			
			# Iterate through text nodes and extract lines
			doc.children.each do |node|
				line  ||= ''
				markup  = node.name
				text    = node.text
				text.split(/\s+/).each do |word|	# Split text into words
					# Check if adding the word to the current line exceeds page width
					if @pdf.width_of("#{line} #{word}", inline_format: true) > @pdf.bounds.width
						line = "<#{markup}>#{line}</#{markup}>" if markup != "text"
						lines << line
						line  = '' # set a new line
						line += word
					else
						line += ' ' unless line.empty?
						line += word
					end
				end
				line = "<#{markup}>#{line}</#{markup}>" if markup != "text"
				lines << line unless line.last == line
			end

			lines
		end

		# convert any image file to png
		def image_to_png(image_file)
			ImageProcessing::Vips.source(image_file).convert!("png")
		end

		# Render content
		def render_child(child, key=nil)
			case child.name
			when 'action-text-attachment'
				blob = ActiveStorage::Blob.find_by(key:)
				img  = StringIO.open(blob&.download)
				if blob&.metadata[:height] > blob&.metadata[:width]
					img = rotate_image(image: img)
				end
				hfit = [@pdf.bounds.width - 2*GUTTER, blob.metadata[:width]].min
				vfit = [PIC_HEIGHT, blob.metadata[:height]].min + 12
				start_new_page_if_needed(vfit)
				@pdf.image img, fit: [hfit, vfit], position: :center
				@pdf.text(child[:caption], size: 10, styles: [:italic], align: :center) if child[:caption]
				return 1 # add one to the key index
			else
				lines = extract_text_lines(child&.to_html)
				lines.each_with_index do |line|
					start_new_page_if_needed(content_height(line))
					PrawnHtml.append_html(@pdf, line)
				end
				return 0 # add nothing to the key index
			end
		end

		# render the pdf table as a header
		def render_header
			if @header_width
				@pdf.table(@header,	width: @header_width)
			else
				@pdf.table(@header)
			end
		end

		# render footers for pdf pages
		def render_footer
			# Add page numbers and drill author to footer
			if @footer
				@pdf.bounding_box([@pdf.bounds.left + 10, @pdf.bounds.bottom + 20], width: @pdf.bounds.width) do
					@pdf.fill_color = '8b8680'	# mid gray font
					@pdf.text @footer, size: 10
				end
			end
			@pdf.bounding_box([@pdf.bounds.right - 20, @pdf.bounds.bottom + 20], width: @pdf.bounds.width) do
				@pdf.fill_color = '8b8680'	# mid gray font
				@pdf.number_pages "# <page>", size: 10
			end
		end

		# rotate an image object
		def rotate_image(image:, angle: 270)
			img = Vips::Image.new_from_buffer(image.read, "")
			img = img.rot("d#{angle}")
			StringIO.new(img.write_to_buffer(".png"))
		end

		# header of a pdf page. basically expecting 2 rows
		# [icon] - [title, some optional fields]
		#        - [subttle, some additonal optonal fields]
		def set_header(header, full)
			cells  = []
			@header_height = 14 * header.size
			@header_width  = (full ?  @pdf.bounds.width : nil)
			header.each do |row|
				cells << []
				row.each do |item|	# check the imtes in the row
					cell = setup_new_cell(item)
					case item[:kind]
					when "gap"; cell[:content] = " "
					when "header-icon", "icon"
						img_file = Rails.root.join('app', 'assets', 'images', item[:value])
						img_png  = image_to_png(img_file)
						img_fit  = (item[:kind] == "icon" ? [16, 16] : [32, 32])
						cell[:image] = img_png
						cell[:fit]   = img_fit
						cell[:padding]   = [0, 0, 0, (item[:kind]== "icon" ? 20 : 0)]
						cell[:position]  = :center
						cell[:rowspan]   = 2 if item[:kind] == "header-icon"
						cell[:vposition] = :top
					when "subtitle"
						cell[:align]      = :left
						cell[:font_style] = :bold
						cell[:padding]   = [0, 0, 0, 10]
						cell[:size]       = 10
						cell[:valign]     = :top
					when "title"
						cell[:align]      = :left
						cell[:colspan]  ||= 2
						cell[:font_style] = :bold
						cell[:padding]   = [0, 0, 0, 10]
						cell[:size]       = 12
						cell[:text_color] =  "000080"
					else # just print regular text
						cell[:align]   = :left
						cell[:padding] = [0, 0, 0, 5]
						cell[:size]    = 10
						cell[:valign]  = :top
					end
					cells.last << cell if cell[:content].present?
				end
			end
			cells
		end

		# setup a table cell based on hash of passed options
		def setup_new_cell(item)
			cell = {content: item[:value]}
			cell[:border_widths] = [0, 0, 0, 0]
			cell[:colspan] = item[:cols].to_i if item[:cols].present?
			cell[:rowspan] = item[:rows].to_i if item[:rows].present?
			cell[:padding] = [0, 0, 0, 0]
			cell
		end

		# setup header/footer && place curser where appropriate
		def setup_new_page
			render_header if @header
			render_footer if @footer
			@pdf.fill_color = '404040'	# back to regular color: black
			@pdf.y          = @pdf.bounds.top - (@header.present? ? @header_height : GUTTER) # Move cursor below the header
			@pdf.font_size(FONT_SIZE)
		end

		# Start a new page if there's not enough space left
		def start_new_page_if_needed(content_height)
			pdf_new_page unless enough_space_for_content?(content_height)
		end
end
