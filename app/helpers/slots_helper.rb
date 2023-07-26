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
module SlotsHelper
	# return icon and top of FieldsComponent
	def slot_title_fields(title:)
		res = title_start(icon: "timetable.svg", title: title)
		res << [{kind: "subtitle", value: @season ? @season.name : ""}]
		res
	end

	# return FieldsComponent @fields for forms
	def slot_form_fields(title:)
		res = slot_title_fields(title:)
		res << [
			{kind: "icon", value: "team.svg"},
			{kind: "select-collection", key: :team_id, options:  @season ? Team.for_season( @season.id) : Team.real, value: @slot.team_id, cols: 2}
		]
		res << [
			{kind: "icon", value: "location.svg"},
			{kind: "select-collection", key: :location_id, options:  @season ?  @season.locations.practice.order(name: :asc) : Location.practice, value: @slot.location_id, cols: 2}
		]
		res << [
			{kind: "icon", value: "calendar.svg"},
			{kind: "select-box", key: :wday, value: @slot.wday, options: weekdays},
			{kind: "time-box", hour: @slot.hour, mins: @slot.min}
		]
		res << [
			{kind: "icon", value: "clock.svg"},
			{kind: "number-box", key: :duration, min:60, max: 120, step: 15, size: 3, value: @slot.duration, units: I18n.t("calendar.mins")}
		]
		res.last << {kind: "hidden", key: :season_id, value:  @season.id} if  @season
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
