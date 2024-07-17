# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
module SlotsHelper
	# return icon and top of FieldsComponent
	def slot_title_fields(title:, subtitle: nil)
		icon = "timetable.svg"
		res  = title_start(icon: , title:, subtitle:)
		res
	end

	# return FieldsComponent @fields for forms
	def slot_form_fields(title:)
		res = slot_title_fields(title:, subtitle: @season&.name)
		res << [
			icon_field("team.svg"),
			{kind: "select-collection", key: :team_id, options: @club.teams.where(season_id: @season.id), value: @slot.team_id, cols: 2}
		]
		res << [
			icon_field("location.svg"),
			{kind: "select-collection", key: :location_id, options: @locations, value: @slot.location_id, cols: 2}
		]
		res << [
			icon_field("calendar.svg"),
			{kind: "select-box", key: :wday, value: @slot.wday, options: weekdays},
			{kind: "time-box", hour: @slot.hour, mins: @slot.min, mandatory: true}
		]
		res << [
			icon_field("clock.svg"),
			{kind: "number-box", key: :duration, min:60, max: 120, step: 15, size: 3, value: @slot.duration, units: I18n.t("calendar.mins"), mandatory: {min: 60}}
		]
		res.last << {kind: "hidden", key: :season_id, value: @season.id}
		res
	end

	# search bar for slots index
	def slot_search_bar(full=false)
		l_opts   = @locations.practice.select(:id, :name)
		l_filter = {kind: "search-collection", key: :location_id, options: l_opts, value: @location.id}
		fields   = [l_filter, {kind: "hidden", key: :club_id, value: @clubid}]
		if full
			s_filter = {kind: "search-collection", key: :season_id, options: Season.real, value: @season&.id}
			fields = [s_filter] + fields
			res = []
		else
			fields << {kind: "hidden", key: :season_id, value: @seasonid}
			res = [gap_field(size: 1)]
		end
		res << {kind: "search-box", url: club_slots_path(@clubid), fields:}
	end

	# fields for individual slot views
	def slot_show_fields
		res = [
			[icon_field("category.svg"), string_field(@slot.team.category.name, cols: 2)],
			[icon_field("division.svg"), string_field(@slot.team.division.name, cols: 2)],
			[icon_field("location.svg"), string_field(@slot.court, cols: 2)],
			[icon_field("calendar.svg"), string_field(@slot.to_s, cols: 2)]
		]
		if u_manager?
			res << [gap_field(cols: 2), button_field({kind: "delete", url: slot_path(@slot), name: @slot.to_s}, align: "right")]
		end
		res
	end

	private
		# returns an array with weekday names and their id
		def weekdays
			res =[]
			1.upto(5) {|i|res << [I18n.t("calendar.daynames")[i], i]}
			res
		end
end
