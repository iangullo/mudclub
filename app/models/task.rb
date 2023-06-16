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
class Task < ApplicationRecord
	belongs_to :event
	belongs_to :drill
	has_rich_text :remarks
	self.inheritance_column = "not_sti"

	def to_s
		self.drill ? self.drill.nice_string : I18n.t("drill.default")
	end

	def s_dur
		self.duration.to_s + "\'"
	end

	def headstring
		"#{self.order.to_s.rjust(2, "0")} - #{self.to_s} (#{self.s_dur})"
	end

	# Takes the input received from add_task (f_object)
	# and either reads or creates a matching drill_target
	def self.fetch(f_object)
		res = Task.find_by(id: f_object[:id].to_i) if f_object[:id].present?
		res = Task.new unless res
		res.order    = f_object[:order].to_i
		res.drill_id = f_object[:drill_id].to_i
		res.duration = f_object[:duration].to_i
		res.remarks  = f_object[:remarks]
		return res
	end
end
