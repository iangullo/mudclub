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
	def slot_title_fields(title:)
		title_start(icon: "timetable.svg", title:, subtitle: @season&.name)
	end

	# return FieldsComponent @fields for forms
	def slot_form_fields(title:)
		res = slot_title_fields(title:)
		res << [
			{kind: "icon", value: "team.svg"},
			{kind: "select-collection", key: :team_id, options: @club.teams.where(season_id: @season.id), value: @slot.team_id, cols: 2}
		]
		res << [
			{kind: "icon", value: "location.svg"},
			{kind: "select-collection", key: :location_id, options: @locations, value: @slot.location_id, cols: 2}
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
		res.last << {kind: "hidden", key: :season_id, value: @season.id}
		res
	end

	# search bar for slots index
	def slot_search_bar
		#options = @locations.practice.pluck(:id,:name).map {|id, name| {location_id: id, name: name}}
		options = @locations.practice.select(:id, :name)
		fields  = [
			{kind: "search-collection", key: :location_id, options:, value: @location.id},
			{kind: "hidden", key: :club_id, value: @clubid},
			{kind: "hidden", key: :season_id, value: @seasonid},
		]
		[gap_field(size: 1), {kind: "search-box", url: club_slots_path(@clubid), fields:}]
	end

	private
		# returns an array with weekday names and their id
		def weekdays
			res =[]
			1.upto(5) {|i|res << [I18n.t("calendar.daynames")[i], i]}
			res
		end
end
