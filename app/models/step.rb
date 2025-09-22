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
	belongs_to :drill, touch: true
	has_paper_trail
	default_scope { order(:order) }

	after_initialize :initialize_new_step, if: :new_record?

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
		# only called if new_record => setup order and copy prior svgdata
		def initialize_new_step
			return unless drill

			# Get last active step in a single query (persisted + non-destroyed)
			last_active = drill.steps.reverse_each.find do |step|
				next if step == self	# Skip if it's the current new step

				# Skip destroyed steps
				!step.marked_for_destruction? &&
				!(step.persisted? && step._destroy == "1")
			end

			# Handle order assignment
			self.order = last_active ? last_active.order.to_i + 1 : 1

			# Copy SVG data if available
			self.svgdata = last_active.svgdata.deep_dup if last_active&.svgdata.present?
		end

		# Validates the structure of SVG data if present
		def svgdata_structure
			return if svgdata.blank?
			unless svgdata.is_a?(Hash)
				errors.add(:svgdata, "must be a hash")
				return
			end
			# Normalize keys upfront
			data = svgdata.with_indifferent_access
			validate_symbols(data[:symbols])
			validate_paths(data[:paths])
		end

		def validate_symbols(symbols)
			unless symbols.is_a?(Array)
				errors.add(:svgdata, "'symbols' must be an array")
				return
			end

			symbols.each do |sym|
				sym = sym.with_indifferent_access
				id = sym[:id] || "unnamed"

				validate_symbol(id, sym)
			end
		end

		def validate_paths(paths)
			return unless paths  # Allow nil paths

			unless paths.is_a?(Array)
				errors.add(:svgdata, "'paths' must be an array")
				return
			end

			allowed_styles = %w[solid dashed wavy double]
			allowed_endings = %w[arrow tee none]

			paths.each do |path|
				path = path.with_indifferent_access
				id = path[:id] || "unnamed"

				validate_path(id, path, allowed_styles, allowed_endings)
			end
		end

		def validate_symbol(id, sym)
			# Required fields
			errors.add(:svgdata, "symbol #{id} must have a 'symbol_id'") unless sym[:symbol_id].is_a?(String)
			errors.add(:svgdata, "symbol #{id} must have numeric 'x' and 'y'") unless valid_position?(sym[:x], sym[:y])

			# Optional fields
			validate_transform(id, sym[:transform])
			validate_string(id, sym[:label], "label")
			validate_color(id, sym[:fill], "fill")
			validate_color(id, sym[:stroke], "stroke")
			validate_color(id, sym[:textColor], "textColor")
		end

		def validate_path(id, path, allowed_styles, allowed_endings)
			# Required fields
			errors.add(:svgdata, "path #{id} must have a 'points' array") unless valid_points?(path[:points])

			# Curve can be boolean or string representation
			unless [ true, false, "true", "false" ].include?(path[:curve])
				errors.add(:svgdata, "path #{id} must have 'curve' set to true or false")
			end

			# Optional fields
			if path[:style]
				unless allowed_styles.include?(path[:style])
					errors.add(:svgdata, "path #{id} 'style' must be one of: #{allowed_styles.join(', ')}")
				end
			end

			if path[:ending] && !allowed_endings.include?(path[:ending])
				errors.add(:svgdata, "path #{id} 'ending' must be one of: #{allowed_endings.join(', ')} or omitted")
			end

			validate_color(id, path[:stroke], "stroke")
		end

		# -- Validation Helpers --

		def valid_position?(x, y)
			x.is_a?(Numeric) && y.is_a?(Numeric)
		end

		def valid_points?(points)
			points.is_a?(Array) && points.all? { |pt| pt.is_a?(Array) && pt.size == 2 && pt.all? { |coord| coord.is_a?(Numeric) } }
		end

		def validate_transform(id, transform)
			return if transform.nil?

			unless transform.is_a?(String)
				errors.add(:svgdata, "symbol #{id} 'transform' must be a string if present")
			end
		end

		def validate_string(id, value, field)
			return if value.nil?

			unless value.is_a?(String)
				errors.add(:svgdata, "symbol #{id} '#{field}' must be a string if present")
			end
		end

		def validate_color(id, value, field)
			return if value.nil?

			unless value.is_a?(String) && value.match?(/^#(?:[0-9a-fA-F]{3}){1,2}$/)
				errors.add(:svgdata, "symbol #{id} '#{field}' must be a valid hex color")
			end
		end
end
