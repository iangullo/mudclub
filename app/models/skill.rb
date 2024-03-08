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
class Skill < ApplicationRecord
	has_and_belongs_to_many :drills
	pg_search_scope :search_by_concept,
		against: :concept,
		ignoring: :accents,
		using: { tsearch: {prefix: true} }
	scope :real, -> { where("id>0").order(:concept) }
	scope :search, -> (s_s) { search_by_concept(s_s).order(:concept) }
	scope :orphans, -> { left_outer_joins(:drills).where("drills.id IS NULL OR drills.id = 0") }
	self.inheritance_column = "not_sti"

	def to_s
		self.concept
	end

	# Takes the input received from a skill_form (f_object)
	# and either reads or returns nil
	def self.fetch(f_object)
		res = (f_object[:id] and f_object[:id].to_i>0) ? Skill.find_by(id: f_object[:id]) : Skill.search(f_object[:concept].strip).first
		return res
	end

	# return an array with all available Skill names
	def self.list
		res  = []
		Skill.real.order(:concept).each {|skill| res << skill.concept}
		res
	end
end
