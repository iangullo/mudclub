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
# frozen_string_literal: true
#
# AccordionField class for FieldsComponents
# conceived to serve as abstraction layer for Grid elements. Relies on
# AccordionComponent.
class AccordionField < AaBaseField
	def initialize(field, form=nil, session=nil)
		super(field, form, session)
		@content = AccordionComponent.new(field)
	end

	def form=(formobj)
		@form         = formobj
		@content.form = formobj
	end

	def session=(sessobj)
		@session         = sessobj
		@content.session = sessobj
	end

	def render
		@content.render
	end
end