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
# View helpers for MudClub sports
module SportsHelper
	# sports page for admins
	def sports_table
		title = [ { kind: :normal }, { kind: :normal, value: I18n.t("sport.single") }, { kind: :normal, value: I18n.t("team.many") } ]
		# title << button_field({kind: :add, url: new_sport(rdx: @rdx), frame: "modal"})
		rows = Array.new
		Sport.all.each { |sport|
			row = { url: sport_path(sport, rdx: @rdx), items: [] }
			row[:items] << symbol_field("icon", { namespace: sport&.name, size: "20x20" }, align: "center", class: "border p-1")
			row[:items] << { kind: :normal, value: sport.to_s, align: "center" }
			row[:items] << { kind: :normal, value: sport.teams.count, align: "center" }
			# row[:items] << button_field({kind: :delete, url: row[:url], name: sport.to_s})
			rows << row
		}
		{ title: title, rows: rows }
	end

	# show sport & related objects
	def sports_show
		res = title_start(icon: symbol_hash("icon", namespace: @sport.name), title: I18n.t("sport.single"), subtitle: @sport.to_s)
		res << [
			button_field({ kind: :jump, symbol: sport_symbol("rules"), url: rules_sport_path(@sport, rdx: @rdx), label: I18n.t("sport.rules"), frame: "modal" }, align: "center"),
			button_field({ kind: :jump, symbol: sport_symbol("category"), url: sport_categories_path(@sport, rdx: @rdx), label: I18n.t("category.many"), frame: "modal" }, align: "center"),
			button_field({ kind: :jump, symbol: sport_symbol("division"), url: sport_divisions_path(@sport, rdx: @rdx), label: I18n.t("division.many"), frame: "modal" }, align: "center")
		]
		res
	end

	# sports edit fields
	def sports_form(title:)
		res = title_start(icon: sport_symbol("category"), title:)
		res << [
				{ kind: :label, value: @sport.to_s, mandatory: { length: 3 } }
			]
		res.last << { kind: :hidden, key: :rdx, value: @rdx } if @rdx
		res
	end

	# common title block for all rules views
	def sport_rules_title(title)
		title_start(icon: sport_symbol("rules"), title:, subtitle: @sport.to_s)
	end

	# show sport & related objects
	# sport rules limits are read as:
	# {rules: {roster: {max:, min:}, playing: {max:, min:}, periods: {regular:, extra:}, duration: {regular:, extra:}, outings: {first:, max:, min:}}}
	def sports_rules
		@sport.rules_limits
	end

	def sport_symbol(concept, namespace: "sport", type: "icon", variant: "default", css: nil, size: nil)
		symbol_hash(concept, namespace:, type:, variant:, css:, size:)
	end
end
