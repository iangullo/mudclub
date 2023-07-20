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
class Division < ApplicationRecord
	before_destroy :unlink
	belongs_to :sport
	has_many :teams
	scope :real, -> { where("id>0").order(:name) }
	scope :for_sport, -> (sport_id) { (sport_id and sport_id.to_i>0) ? where(sport_id: sport_id.to_i).order(:name) : where("sport_id>0").order(:name) }

	def to_s
		self.id==0 ? I18n.t("scope.none") : self.name
	end

	# parse raw form data to update object values
	def rebuild(f_data)
		self.name = f_data[:name] if f_data[:name]
	end

	private
		# cleanup dependent teams, reassigning to 'dummy' category
		def unlink
			self.teams.update_all(category_id: 0)
		end
end
