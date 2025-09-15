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
module DivisionsHelper
	# return icon and top of GridComponent
	def division_title(title:, subtitle: @sport&.to_s, cols: nil)
		title_start(icon: symbol_hash("division", namespace: "sport"), title:, subtitle:, rows: 2, cols:)
	end

	def division_show
		division_title(title: I18n.t("division.single"), subtitle: @division.name)
	end

	# return GridComponent @fields for forms
	def division_form(action)
		@submit = SubmitComponent.new(submit: :save)
		res = division_title(title: I18n.t("division.#{action}"))
		res << [ gap_field, { kind: :text_box, key: :name, value: @division.name, placeholder: I18n.t("division.name"), mandatory: { length: 3 } } ]
	end

	# return table for @divisions TableComponent
	def division_table
		title = [ { kind: :normal, value: I18n.t("division.name") } ]
		title << button_field({ kind: :add, url: new_sport_division_path(@sport, rdx: @rdx), frame: "modal" }) if u_admin?

		rows = Array.new
		@divisions.each do |div|
			row = { url: edit_sport_division_path(@sport, div, rdx: @rdx), frame: "modal", items: [] }
			row[:items] << { kind: :normal, value: div.name }
			row[:items] << button_field({ kind: :delete, url: sport_division_path(@sport, div, rdx: @rdx), name: div.name }) if u_admin?
			rows << row
		end
		table_field(title:, rows:, align: :center)
	end
end
