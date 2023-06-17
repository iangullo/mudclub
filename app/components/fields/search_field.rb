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
# SearchField class for FieldsComponents
# conceived to serve as abstraction layer for all Search boxes. Relies on
# SearchComponent.
class SearchField < BaseField
	INPUT_CLASS = "block px-1 py-0 w-full text-gray-900 bg-gray-50 shadow-inner rounded border-1 border-gray-300 appearance-none focus:outline-none focus:ring-0 focus:border-blue-700 peer".freeze

	def initialize(field, session)
		super(field)
		i_class = [INPUT_CLASS]
		i_class << ((@fdata[:label] || @fdata[:fields]) ? "mt-3" : "align-middle")
		@fdata[:class]   = "inline-flex rounded-md border-2 border-gray-300"
		@fdata[:i_class] = i_class.join(" ")
		@fdata[:align] ||= "left"
		@fdata[:size]  ||= 16
		@fdata[:lines] ||= 1
		@fdata[:fields]  = [[{kind: @fdata[:kind], key: @fdata[:key].to_sym, label: @fdata[:label], options: @fdata[:options], value: @fdata[:value]}]] unless @fdata[:kind] == "search-combo"
		@fdata[:kind]    = "search-combo"
		@content         = SearchComponent.new(search: @fdata, session:)
	end
end