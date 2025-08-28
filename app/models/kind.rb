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
class Kind < ApplicationRecord
	has_many :drills
	before_save { self.name = self.name.mb_chars.titleize }
	scope :real, -> { where("id>0").order(:name) }
	pg_search_scope :search,
		against: :name,
		ignoring: :accents,
		using: { tsearch: { prefix: true } }
	scope :orphans, -> { left_outer_joins(:drills).where("drills.id IS NULL OR drills.id = 0") }
	self.inheritance_column = "not_sti"

	# Takes the input received from a skill_form (s_kind - string)
	# and either reads or creates a matching Kind
	def self.fetch(s_kind)
		res = Kind.create(name: s_kind.strip) unless (res = Kind.search(s_kind.strip).first)
		res
	end

	# return an array with all available Kind names
	def self.list
		res  = []
		Kind.real.order(:name).each { |kind|	res << kind.name }
		res
	end
end
