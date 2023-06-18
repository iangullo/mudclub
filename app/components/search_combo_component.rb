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

# SearchComboComponent - ViewComponent to render a combo search.
# relies on custom javascript "search-form" functionality.
# Receives search: as starting point:
# => search: a Hash with the follwing fields (at least)
#			* url: URL to call when searching
#			* l_class: Tailwind classes for label (optional)
#			* i_class: Tailwind classes for each search field
#			* fields: Array of search fields. Each with:
#				-> label: label linked to search field (optional)
#				-> key: search to linked to specific object key
#				-> kind: kind of search field to use: (search-text | search-select | search-collection | hidden)
#				-> options: list of options that can be selected (needed for search-select and search-collection)
#				-> value: initial value to search for in the field
class SearchComboComponent < ApplicationComponent

	def initialize(search:)
		@search   = search
		@s_action = {action: "input->search-form#search"}
		search[:fields].each {|field|
			field[:placeholder] = I18n.t("action.search") unless field[:placeholder] if field[:kind]=="search-text"
		}
	end
end
