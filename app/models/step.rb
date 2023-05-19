# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
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
# Handle each "Step" for a Drill
class Step < ApplicationRecord
  belongs_to :drill
  has_one_attached :diagram
	has_rich_text :description
	self.inheritance_column = "not_sti"

  # how many columns to display it?
  def view_cols
    desc = self.description.try(:length).to_i>0
    diag = self.diagram.attached?
    (desc and diag) ? 1 : 2
  end

  # remove an attached diagram
  def remove_diagram(value)
    if ActiveModel::Type::Boolean.new.cast(value) && diagram.attached?
      diagram.purge_later
    end
  end

  # replace the atached diagram
  def replace_diagram(file)
    diagram.attach(file) if file.present?
  end

  # Fetches a Step from the database - or creteas one it not found
  def self.fetch(s_data)
    if s_data[:id].try(:to_i)>0
      res = Step.find_by(id: s_data[:id])
    else
      res = Step.new(order: s_data[:order], description: s_data[:description], diagram: s_data[:diagram])
      res.diagram.attach(s_data[:diagram]) if s_data[:diagram].present?
    end
    res
  end
end
