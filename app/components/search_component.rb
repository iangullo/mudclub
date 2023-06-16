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

# SearchComponent - ViewComponent to render a combo search.
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
class SearchComponent < ApplicationComponent
	DIV_CLASS   = "inline-flex rounded-md border-2 border-gray-300"
	LABEL_CLASS = "absolute text-md font-semibold text-gray-700 duration-300 transform -translate-y-4 scale-75 top-2 z-10 origin-[0] bg-transparent px-0 peer-focus:px-0 peer-focus:text-blue-700 peer-placeholder-shown:scale-100 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:top-1/2 peer-focus:top-2 peer-focus:scale-75 peer-focus:-translate-y-4 left-0"

	def initialize(search:, session:)
		@search   = search
		@session  = session
		@s_action = {action: "input->search-form#search"}
		search[:fields].each do |field|
			field[:placeholder] = I18n.t("action.search") unless field[:placeholder] if field[:kind]=="search-text"
		end
	end

	def render
		content_tag(:div, id: "combo-search-box", class: DIV_CLASS) do
			render_search_form
		end
	end

	private

		def render_search_form
			form_with(
				url: @search[:url],
				method: :get,
				data: {
					controller: "search-form",
					search_text_target: "fsearch",
					turbo_frame: "search-results"
				}
			) do |fsearch|
				content_tag(:table) do
					content_tag(:tr, class: "inline-flex") do
						render_search_fields(fsearch)
						content_tag(:td) do
							fsearch.submit("search.svg", height: 25, class: "align-middle", alt: t("action.search"))
						end
          end
				end
			end
		end

		def render_search_fields(fsearch)
			@search[:fields].each do |opt|
				content_tag(:td, class: "relative") do
					render_search_label(opt) + render_search_input(fsearch, opt)
				end
			end.join("\n").html_safe
		end

		def render_search_label(opt)
			return ""	unless opt[:label]
			"<label for='#{opt[:key]}' class='#{LABEL_CLASS}'>#{opt[:label]}</label>"
		end

		def render_search_input(fsearch, opt)
			case opt[:kind]
			when "search-text"
				fsearch.text_field(
					opt[:key],
					placeholder: opt[:placeholder],
					value: opt[:value],
					size: opt[:size],
					class: @search[:i_class],
					data: @s_action
				)
			when "search-select"
				fsearch.select(
					opt[:key],
					options_for_select(
						opt[:options],
						@session.dig(opt[:key].to_sym) ? @session.dig(opt[:key].to_sym).to_i : opt[:value]),
						{include_blank: t("scope.all")},
						{class: @search[:i_class]}
					)
			when "search-collection"
				fsearch.collection_select(
					opt[:key],
					opt[:options],
					:id,
					:name,
					{selected: params[opt[:key].to_sym] ? params[opt[:key].to_sym] : opt[:value]},
					{class: @search[:i_class]}
				)
			when "hidden"
				fsearch.hidden_field(opt[:key].to_sym, value: opt[:value])
			end
		end
end
