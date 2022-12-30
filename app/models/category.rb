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
	has_many :teams
	scope :real, -> { where("id>0").order(min_years: :desc) }
	enum rules: {
		fiba: 0,
		q4: 1,
		q6: 2
	}

	def to_s
		self.name
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
		case self.max_years
		when 13	then return :q4 #U14 uses pas4
		when 11	then return :q5 #U12 uses pas6 (minibasket)
		when 9	then return :q4 #U12 uses pas4 (premini)
		else return :fiba
		end
	end

	# return time rules that may apply to this a category
	# BASKETBALL:  FIBA: free, pas4: 1-2/3+1 Qs; pas6: 2-3/5+1 Qs
	def self.time_rules
		[
			[I18n.t("category.fiba"), :fiba],
			[I18n.t("category.q4"), :q4],
			[I18n.t("category.q6"), :q6]
		]
	end
end
