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
# app/models/people/person_resolution.rb
class PersonResolution
	attr_reader :status, :person, :people, :conflicts, :matched_by

	def initialize(status:, person: nil, people: [], conflicts: {}, matched_by: nil)
		@status     = status
		@person     = person.is_a?(Person) ? person : nil
		@people     = Array(people)
		@conflicts  = conflicts
		@matched_by = matched_by
	end

	def ok?
		%i[exact probable ok].include?(status)
	end

	def exact?
		status == :exact
	end

	def probable?
		status == :probable
	end

	def ambiguous?
		status == :ambiguous
	end

	def conflict?
		status == :conflict
	end

	def none?
		status == :none
	end

	def missing?
		status == :missing
	end

	def candidates
		people.presence || Array(person)
	end
end
