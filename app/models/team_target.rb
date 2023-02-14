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
class TeamTarget < ApplicationRecord
	belongs_to :team
	belongs_to :target
	scope :global, -> { where(month: 0) }
	scope :plan, -> { where("month>0") }
	scope :monthly, -> (month) { where(month: month) }
	accepts_nested_attributes_for :target, reject_if: :all_blank
	self.inheritance_column = "not_sti"

	def to_s
		if self.priority
			cad = (self.priority > 0) ? "(" + self.priority.to_s + ") " : ""
		else
			cad = ""
		end
		cad = cad + self.target.concept
	end

	#wrapper to get aspect of associated Target
	def aspect
		self.target.aspect_before_type_cast
	end

	#wrapper to get focus of associated Target
	def focus
		self.target.focus_before_type_cast
	end

	# Takes the input received from target_form (f_object)
	# and either reads or creates a matching drill_target
	def self.fetch(f_object)
		tid = f_object[:id].to_i > 0 ? f_object[:id].to_i : nil
		res = tid ? TeamTarget.find(tid) : TeamTarget.new
		t   = f_object[:target_attributes]
		tgt = Target.search(t[:id], t[:concept], t[:focus], t[:aspect])
		tgt = Target.new unless tgt # ensure we have a target
		tgt.concept  = t[:concept]        # accept concept edition
		tgt.focus    = t[:focus].length==1 ? t[:focus].to_i : t[:focus].to_sym  # accept focus edition
		tgt.aspect   = t[:aspect].length==1 ? t[:aspect].to_i : t[:aspect].to_sym  # accept aspect edition
		tgt.save unless tgt.persisted?
		res.target   = tgt
		res.priority = f_object[:priority].to_i
		res.month    = f_object[:month].to_i
		return res
	end

	# ensure creation of associated target if required
	def self.nest_create(month:, aspect:, focus:)
		res = TeamTarget.new(month:)
		res.build_target
		res.target.aspect = aspect
		res.target.focus  = focus
		res
	end
end