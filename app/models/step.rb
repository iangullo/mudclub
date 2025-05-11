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
# Handle Steps for Drills/Plays Steps to be able to attach several to a parent.
class Step < ApplicationRecord
	belongs_to :drill

	has_rich_text :explanation
	has_one_attached :diagram

	validate :svgdata_structure

	# Determina el tipo de representación visual del paso
	def representation_type
		return :combo_image if has_text? && has_image? && !has_svg?
		return :combo_svg   if has_text? && has_svg? && !has_image?
		return :image       if has_image? && !has_text? && !has_svg?
		return :svg         if has_svg? && !has_text? && !has_image?
		return :text        if has_text? && !has_image? && !has_svg?
		:empty
	end

	# Verifica si hay contenido de texto enriquecido
	def has_text?
		explanation&.body&.to_plain_text&.strip&.present?
	end

	# Verifica si hay imagen adjunta
	def has_image?
		diagram.attached?
	end

	# Verifica si hay datos SVG válidos
	def has_svg?
		svgdata.present?
	end

	# Cabecera para usar en acordeones u otros identificadores visuales
	def headstring
		"##{order}"
	end

	# De momento se fuerza a 'basketball', pero puede evolucionar
	def sport
		drill.try(:sport) || "basketball"
	end

	# Extrae pasos pasados desde un array estructurado, sin duplicados
	def self.passed(step_array)
		step_array.map(&:last).uniq
	end

	private
	# Valildate SVG data structure
	def svgdata_structure
		unless svgdata.is_a?(Hash)
			errors.add(:svgdata, "must be a hash")
			return
		end
	
		elements = svgdata[:elements] || svgdata["elements"]
		unless elements.is_a?(Array)
			errors.add(:svgdata, "must contain an elements array")
			return
		end
	
		elements.each_with_index do |element, index|
			type = element[:type] || element["type"]
			transform = element[:transform] || element["transform"]
	
			unless type && transform
				errors.add(:svgdata, "element #{index} must have type and transform")
				next
			end
	
			case type
			when "object"
				role  = element[:role] || element["role"]
				label = element[:label] || element["label"]
				unless label.nil? || label.is_a?(String)
					errors.add(:svgdata, "object element #{index} must have a string label or nil")
				end
				unless role
					errors.add(:svgdata, "object element #{index} must include a role")
				end
			when "bezier", "straight"
				points = element[:points] || element["points"]
				stroke = element[:stroke] || element["stroke"]
				style = element[:style] || element["style"]
				ending = element[:ending] || element["ending"]
				unless points.is_a?(Array) && points.all? { |p| p.is_a?(Hash) && p.key?("x") && p.key?("y") }
					errors.add(:svgdata, "path element #{index} must include an array of point hashes with x and y")
				end
				unless stroke.is_a?(String)
					errors.add(:svgdata, "path element #{index} must include a stroke as a string")
				end
				unless style.is_a?(String)
					errors.add(:svgdata, "path element #{index} must include a style as a string")
				end
				unless ending.nil? || ending.is_a?(String)
					errors.add(:svgdata, "path element #{index} must have ending as a string or null")
				end
			else
				errors.add(:svgdata, "unknown type '#{type}' at element #{index}")
			end
		end
	end	
end
	
