# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
module SeasonsHelper
	# return HeaderComponent @fields for forms
	def season_form_fields(title:, cols: nil)
		res = season_title_fields(title:, cols:)
		res << [{kind: "subtitle", value: @season.name}]
		res << [
			{kind: "label", align: "right", value: I18n.t("calendar.start")},
			{kind: "date-box", key: :start_date, s_year: 2020, value: @season.start_date}
		]
		res << [
			{kind: "label", align: "right", value: I18n.t("calendar.end")},
			{kind: "date-box", key: :end_date, s_year: 2020, value: @season.end_date}
		]
		res
	end

	# grid for mudclub seasons
	def season_grid(seasons: @seasons)
		title = [
			{kind: "normal", value: I18n.t("season.single"), align: "center"},
			{kind: "normal", value: I18n.t("team.many"), align: "center"},
			button_field({kind: "add", url: new_season_path, frame: "modal"})
		]
		rows = Array.new
		seasons.each { |season|
			row = {url: season_path(season, rdx: 0), items: [], frame: "modal"}
			row[:items] << {kind: "normal", value: season.name, align: "center"}
			row[:items] << {kind: "normal", value: season.teams.count, align: "center"} 
			row[:items] << button_field({kind: "delete", url: row[:url], name: season.to_s})
			rows << row
		}
		{title:, rows:}
	end

	# return HeaderComponent @fields for forms
	def season_fields(cols: nil)
		res = season_title_fields(title: I18n.t("season.single"), cols:)
		res << [{kind: "subtitle", value: @season.name}]
		res << [
			{kind: "label", align: "right", value: I18n.t("calendar.start")},
			{kind: "text", value: @season.start_date}
		]
		res << [
			{kind: "label", align: "right", value: I18n.t("calendar.end")},
			{kind: "text", value: @season.end_date}
		]
		res
	end


	# return icon and top of HeaderComponent
	def season_title_fields(icon: "calendar.svg", title:, cols: nil)
		title_start(icon:, title:, cols:)
	end
end
