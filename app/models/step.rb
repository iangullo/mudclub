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
# Handles Steps for Drills/Plays. Each step belongs to a parent drill.
class Step < ApplicationRecord
	belongs_to :drill
	default_scope { order(:order) }

	before_validation :set_default_order, on: :create
	has_rich_text :explanation
	has_one_attached :diagram

	validate :svgdata_structure

	# Determines the visual representation type of the step
	def representation_type
		if has_text?
			return :combo_image if has_image? && !has_svg?
			return :combo_svg   if has_svg? && !has_image?
			return :text        if !has_image? && !has_svg?
		elsif has_image? && !has_svg?
			return :image
		elsif has_svg? && !has_image?
			return :svg
		end

		:empty
	end

	# Checks whether rich text content is present
	def has_text?
		explanation&.body&.to_plain_text&.strip&.present?
	end

	# Checks whether attached image is present
	def has_image?
		diagram.attached?
	end

	# Checks whether SVG symbols are present
	def has_svg?
		svgdata.present?
	end

	# Returns a string identifier for use in accordions or visual selectors
	def headstring
		"##{order}"
	end

	# forcing use of 'basketball' as default, but open to change in future
	def sport
		drill.try(:sport) || "basketball"
	end

	# Extracts unique step hashes from the form parameters
	def self.passed(step_params)
		step_params.values.uniq
	end

	private
		# ensure a valid :order is set in the object
		def set_default_order
			self.order ||= (drill.steps.maximum(:order) || 0) + 1 if drill
		end

		# Validates the structure of SVG data if present
		def svgdata_structure
			return if svgdata.blank?
			unless svgdata.is_a?(Hash)
				errors.add(:svgdata, "must be a hash")
				return
			end

			validate_symbols(svgdata["symbols"] || svgdata[:symbols])
			validate_paths(svgdata["paths"] || svgdata[:paths])
		end

		def validate_symbols(symbols)
			unless symbols.is_a?(Array)
				errors.add(:svgdata, "'symbols' must be an array")
				return
			end

			symbols.each_with_index do |sym, index|
				unless sym.is_a?(Hash)
					errors.add(:svgdata, "symbol #{index} must be a hash")
					next
				end

				id         = sym["id"]
				symbol_id  = sym["symbol_id"]
				position   = [sym["x"], sym["y"]]
				transform  = sym["transform"]
				label      = sym["label"]
				fill       = sym["fill"]
				stroke     = sym["stroke"]
				text_color = sym["textColor"]

				errors.add(:svgdata, "symbol #{index} must have a 'symbol_id'") unless symbol_id.is_a?(String)
				errors.add(:svgdata, "symbol #{index} must have a 'position' as [x, y]") unless valid_xy?(position)

				unless valid_svg_transform?(transform)
					errors.add(:svgdata, "symbol #{index} 'transform' must be a valid SVG transform string if present")
				end

				if label && !label.is_a?(String)
					errors.add(:svgdata, "symbol #{index} 'label' must be a string if present")
				end

				if fill && !fill.match?(/^#(?:[0-9a-fA-F]{3}){1,2}$/)
					errors.add(:svgdata, "symbol #{index} 'fill' must be a valid hex color")
				end

				if stroke && !stroke.match?(/^#(?:[0-9a-fA-F]{3}){1,2}$/)
					errors.add(:svgdata, "symbol #{index} 'stroke' must be a valid hex color")
				end

				if text_color && !text_color.match?(/^#(?:[0-9a-fA-F]{3}){1,2}$/)
					errors.add(:svgdata, "symbol #{index} 'textColor' must be a valid hex color")
				end
			end
		end

		def validate_paths(paths)
			return if paths.nil? # paths may be optional
			unless paths.is_a?(Array)
				errors.add(:svgdata, "'paths' must be an array")
				return
			end

			allowed_styles = %w[solid dashed wavy double]
			allowed_endings = %w[arrow T]

			paths.each_with_index do |path, index|
				unless path.is_a?(Hash)
					errors.add(:svgdata, "path #{index} must be a hash")
					next
				end

				curve  = path["curve"]
				ending = path["ending"]
				points = path["points"]
				stroke = path["stroke"]
				style  = path["style"]

				unless points.is_a?(Array) && points.all? { |pt| valid_xy?(pt) }
					errors.add(:svgdata, "path #{index} must include an array of [x, y] points")
				end

				unless curve.in?([true, false])
					errors.add(:svgdata, "path #{index} must have 'curve' set to true or false")
				end

				unless style.is_a?(String) && allowed_styles.include?(stroke)
					errors.add(:svgdata, "path #{index} 'style' must be one of: #{allowed_styles.join(', ')}")
				end

				if ending && !ending.in?(allowed_endings)
					errors.add(:svgdata, "path #{index} 'ending' must be one of: #{allowed_endings.join(', ')} or omitted")
				end

				if stroke && !stroke.match?(/^#(?:[0-9a-fA-F]{3}){1,2}$/)
					errors.add(:svgdata, "path #{index} 'stroke' must be a valid hex color")
				end
			end
		end

		def valid_svg_transform?(transform)
			return true if transform == nil
			return nil unless transform&.is_a?(String)
			transform_regex = /
				\A
				(                               # allow multiple transform functions
					(?:
						translate\(\s*-?\d+(\.\d+)?(?:\s*,\s*-?\d+(\.\d+)?)?\s*\) |
						scale\(\s*-?\d+(\.\d+)?(?:\s*,\s*-?\d+(\.\d+)?)?\s*\) |
						rotate\(\s*-?\d+(\.\d+)?(?:\s*,\s*-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?)?\s*\) |
						skewX\(\s*-?\d+(\.\d+)?\s*\) |
						skewY\(\s*-?\d+(\.\d+)?\s*\) |
						matrix\(\s*-?\d+(\.\d+)?(?:\s*,\s*-?\d+(\.\d+)?){5}\s*\)
					)
					\s*
				)+
				\z
			/x

			!!transform.match(transform_regex)
		end

		def valid_xy?(pair)
			pair.is_a?(Array) && pair.size == 2 &&
				pair[0].is_a?(Numeric) && pair[1].is_a?(Numeric)
		end
end
