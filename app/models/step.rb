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
# Handle Steps for Drills/Plays to be able to attach several to a Play.
class Step < ApplicationRecord
  belongs_to :drill
  has_rich_text :explanation
  has_one_attached :diagram

  validates :order, presence: true, numericality: { only_integer: true }

  def court
    self.drill.court_mode
  end

  
  def has_diagram?
    diagram.attached? || diagram_svg.present?
  end
  
  def image
    diagram_svg.presence || diagram.attachment
  end

  def kind
    has_text = explanation.body.present?
    has_image = diagram.attached?
    has_svg = diagram_svg.present?

    return :combo_image if has_text && has_image && !has_svg
    return :combo_svg if has_text && has_svg && !has_image
    return :image if has_image && !has_text && !has_svg
    return :svg if has_svg && !has_text && !has_image
    return :text if has_text && !has_image && !has_svg
    :empty
  end

  def diagram_svg
    self[:diagram_svg].presence
  end

  # head string for accoerdions
  def headstring
    "##{self.order}"
  end

  def sport
    "basketball" # should be self.drill.sport in future
  end


	# a list of passed steps fo bind to a related object
	def self.passed(s_array)
		a_steps = Array.new	# array to include only non-duplicates
		s_array.each { |step| a_steps << step[1] }
		return a_steps
	end
end
