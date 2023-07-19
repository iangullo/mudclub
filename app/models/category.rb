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
class Category < ApplicationRecord
	before_destroy :unlink
	belongs_to :sport
	has_many :teams
	scope :real, -> { where("id>0").order(min_years: :desc) }

	def to_s
		self.id==0 ? I18n.t("scope.none") : self.name
	end

	def name
		self.age_group.to_s + " " + self.sex.to_s
	end

	# calculate earliest valid birthday date depending on
	# s_year (season year)
	def youngest(s_year)
		DateTime.new(s_year-self.min_years+1,1,1).to_date
	end

	# same for latest valid birthdate
	def oldest(s_year)
		DateTime.new(s_year-self.max_years-1,12,31).to_date
	end

	# default applicable rules
	def def_rules
		self.sport.def_rules
	end

	# parse raw form data to update object values
	def rebuild(f_data)
		self.age_group = f_data[:age_group] if f_data[:age_group]
		self.sex       = f_data[:sex] if f_data[:sex]
		self.min_years = f_data[:min_years] if f_data[:min_years]
		self.max_years = f_data[:max_years] if f_data[:max_years]
		self.rules     = f_data[:rules].to_sym if f_data[:rules]
	end

	private
		# cleanup dependent teams, reassigning to 'dummy' category
		def unlink
			self.teams.update_all(category_id: 0)
		end
end
