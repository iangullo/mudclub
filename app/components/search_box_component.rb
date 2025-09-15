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
# frozen_string_literal: true

# SearchBoxComponent - ViewComponent to render a combo search.
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
class SearchBoxComponent < ApplicationComponent
	D_CLASS = "inline-flex rounded-md border-2 border-gray-300"
	F_CLASS = "inline-flex relative align-middle"
	I_CLASS = "block px-1 py-0 w-full text-gray-900 bg-gray-50 shadow-inner rounded border-1 border-gray-300 appearance-none focus:outline-none focus:ring-0 focus:border-blue-700 peer".split(" ")
	L_CLASS = "absolute text-md font-semibold text-gray-700 duration-300 transform -translate-y-4 scale-75 top-2 origin-[0] bg-transparent px-0 peer-focus:px-0 peer-focus:text-blue-700 peer-placeholder-shown:scale-100 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:top-1/2 peer-focus:top-2 peer-focus:scale-75 peer-focus:-translate-y-4 left-0"
	S_CLASS = "inline-flex align-middle hover:bg-gray-300 rounded-md"

	def initialize(search)
		labels    = false
		@s_url    = search[:url]
		@s_filter = search[:filter].presence
		@s_action = { action: "input->search-form#search" }
		if search[:kind] == :search_box	# we'll get an array of search fields
			@fields = search[:fields]
		else	# we need to create our array of search fields with a single one
			@fields = [ { kind: search[:kind], key: search[:key].to_sym, label: search[:label], options: search[:options], value: search[:value] } ]
		end
		@fields.each  do |field|	# parse placeholders & labels
			labels = true if field[:label].present?
			field[:size]        ||= 17
			field[:placeholder] ||= I18n.t("action.search") if field[:kind] == :search_text
		end
		@i_class  = I_CLASS << (labels ? "mt-3" : "align-middle")
		@i_class  = @i_class.join(" ")
	end

	def call
		form_with(url: @s_url, method: :get, data: { controller: "search-form", search_form_fsearch_target: "fsearch", turbo_frame: "search-results" }) do |fsearch|
			tag.div(id: "search-box", class: D_CLASS) do
				render_search_fields(fsearch)	# First column for fields
				render_submit_button	# Second column for the button
			end
		end
	end

	private
		def field_tag(fsearch, field)
			tag.div(class: F_CLASS) do
				safe_join([
					field[:label].present? ? tag.label(field[:label], for: field[:key], class: L_CLASS) : nil,
					input_field(fsearch, field)
				].compact)
			end
		end

		def hidden_filter_field(fsearch)
			if @s_filter.present?
				fsearch.hidden_field(@s_filter[:key].to_sym, value: @s_filter[:value])
			end
		end

		def input_field(fsearch, field)
			case field[:kind]
			when :search_text
				fsearch.text_field(field[:key], placeholder: field[:placeholder], value: field[:value], size: field[:size], class: @i_class, data: @s_action)
			when :search_select
				fsearch.select(field[:key], options_for_select(field[:options], session.dig(field[:key].to_sym) || field[:value]), { include_blank: field[:blank] || field[:placeholder] }, class: @i_class)
			when :search_collection
				fsearch.collection_select(field[:key], field[:options], :id, :name, { selected: params[field[:key].to_sym].presence || field[:value] }, class: @i_class)
			when :hidden
				fsearch.hidden_field(field[:key], value: field[:value])
			end
		end

		def render_fields(fsearch)
			@fields.map { |field| field_tag(fsearch, field) }
		end

		def render_search_fields(fsearch)
			concat(tag.div(class: "flex flex-wrap m-1") do
				safe_join(render_fields(fsearch) + [ hidden_filter_field(fsearch) ])
			end)
		end

		def render_submit_button
			concat(content_tag(:div, class: S_CLASS) do
				tag.button(type: "submit", class: "p-1 align-middle", aria: { label: t("action.search") }) do
					render SymbolComponent.new("search",
						type: :button,
						label: t("action.search")
					)
				end
			end)
		end
end
