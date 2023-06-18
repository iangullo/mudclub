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
# BaseField class for FieldsComponents
# conceived to serve as abstraction layer to be inherited by different Field classes.
class AaBaseField
	attr_writer :form, :session
	attr_reader :content, :kind

	# basic field information
	def initialize(field, form=nil, session=nil)
		@form            = form	# set form, if passed
		@session         = session
		@fdata           = field	# field data definition
		@fdata[:align] ||= "left"
		@content         = field[:value]
	end

	# accessors for key field data
	def kind
		@fdata[:kind].presence
	end

	def key
		@fdata[:key].presence
	end

	def value
		@fdata[:value].presence
	end

	def cols
		@fdata[:cols].presence
	end

	def rows
		@fdata[:rows].presence
	end

	def align
		@fdata[:align].presence
	end

	def icon
		@fdata[:icon].presence
	end

	def size
		@fdata[:size].presence
	end

	def css_class
		@fdata[:class].presence
	end

	def i_class
		@fdata[:i_class].presence
	end

	def label
		@fdata[:label].presence
	end
end