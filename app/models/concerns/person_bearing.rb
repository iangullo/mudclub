# MudClub - Modular Rails application for managing sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
# app/models/concerns/person_bearing.rb
module PersonBearing
	extend ActiveSupport::Concern

	def modified?
		super || person.modified?
	end

	#------------------------------------
	# Person resolution & data rebuilding
	#------------------------------------
	def resolve_person(person_attributes)
		return unless person_attributes

		if new_record? || person.nil?
			resolution = Person.resolve(person_attributes)

			case resolution[:status]
			when :ambiguous
				errors.add(:base, Person.msg(:ambiguous))
				return false

			when :new, :probable, :exact
				self.person = resolution[:person]
			end
		end

		person.rebuild(person_attributes)

		true
	end
end
