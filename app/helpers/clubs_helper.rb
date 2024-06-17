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
module ClubsHelper
	# return title for @clubs GridComponent
	def club_grid(clubs: @clubs)
		title = [
			{kind: "normal", value: I18n.t("club.logo")},
			{kind: "normal", value: I18n.t("person.name")},
			{kind: "normal", value: I18n.t("person.contact")}
		]
		title << button_field({kind: "add", url: new_club_path, frame: "modal"}) if u_admin?

		rows = Array.new
		clubs.each { |club|
			row = {url: club_path(club), items: []}
			row[:items] += [
				icon_field(club.logo, align: "center"),
				{kind: "normal", value: club.nick},
				{kind: "contact", phone: club.phone, email: club.email, device: device}
			]
			row[:items] << button_field({kind: "delete", url: row[:url], name: club.to_s, align: "left"}) if (club != u_club && u_admin?)
			rows << row
		}
		{title:, rows:}
	end

	# FieldComponent fields for club links
	def club_links
		if user_in_club?	# user's club
			res = [
				[
					button_field({kind: "jump", icon: "player.svg", url: club_players_path(@club, rdx: 0), label: I18n.t("player.many")}, align: "center"),
					button_field({kind: "jump", icon: "coach.svg", url: club_coaches_path(@club, rdx: 0), label: I18n.t("coach.many")}, align: "center"),
					button_field({kind: "jump", icon: "team.svg", url: club_teams_path(@club, rdx: 0), label: I18n.t("team.many")}, align: "center")
				],
				[
					button_field({kind: "jump", icon: "rivals.svg", url: clubs_path(rdx: 0), label: I18n.t("club.rivals")}, align: "center"),
					button_field({kind: "jump", icon: "location.svg", url: club_locations_path(@club, rdx: 0), label: I18n.t("location.many")}, align: "center"),
					button_field({kind: "jump", icon: "timetable.svg", url: club_slots_path(@club, rdx: 0), label: I18n.t("slot.many")}, align: "center")
				]
			]
		else
			res = [[
				button_field({kind: "jump", icon: "team.svg", url: club_teams_path(@club, rdx: 0), label: I18n.t("team.many")}, align: "center"),
				button_field({kind: "jump", icon: "location.svg", url: club_locations_path(@club, rdx: 0), label: I18n.t("location.many")}, align: "center")
			]]
		end
		res
	end

	# FieldComponent fields to show a club
	def club_show_title(rows: 3, cols: 2)
		res = club_title_fields(title: @club.nick, icon: @club.logo, rows:, cols:)
		res << [{kind: "text", value: @club.name, cols:}]
		res << [{kind: "contact", website: @club.website, phone: @club.phone, email: @club.email, device: device}]
		res
	end

	# return Club FieldsComponent @fields for forms
	def club_form_title(title:, cols: 2)
		res = club_title_fields(title:, icon: @club.logo, rows: 3, cols:, form: true)
		res << [{kind: "text-box", key: :nick, value: @club.nick, placeholder: I18n.t("person.name"), cols:}]
		res << [{kind: "text-box", key: :name, value: @club.name, size: 27, placeholder: I18n.t("club.entity"), cols:}]
	end

	# return Club FieldsComponent @fields for forms
	def club_form_fields(cols: 5)
		iclass = "align-top mr-1"
		res = [[
			icon_field("website.svg", iclass:),
			{kind: "text-box", key: :website, value: @club.website, placeholder: I18n.t("club.website"), size: 31, cols:}
		]]
		res << [	# locale/country settings
			icon_field("phone.svg", iclass:),
			{kind: "text-box", key: :phone, size: 12, value: @club.phone, placeholder: I18n.t("person.phone")},
			icon_field("flag.svg", tip: I18n.t("locale.country"), tipid: "ctry"),
			{kind: "text-box", align: "left", key: :country, value: @club.country, placeholder: "US", size: 2},
			icon_field("locale.png", tip: I18n.t("locale.lang"), tipid: "lang"),
			{kind: "select-box", align: "left", key: :locale, options: User.locale_list, value: @club.locale},
		]
		res << [
			icon_field("at.svg", iclass:),
			{kind: "email-box", key: :email, value: @club.email, placeholder: I18n.t("person.email"), size: 34, cols:}
		]
		res << [
			icon_field("home.svg", iclass:),
			{kind: "text-area", key: :address, size: 34, cols:, lines: 3, value: @club.address, placeholder: I18n.t("person.address")},
		]
	end

	# return icon and top of FieldsComponent
	def club_title_fields(title:, subtitle: nil, icon: "mudclub.svg", rows: 2, cols: nil, form: nil)
		title_start(icon:, title:, subtitle:, rows:, cols:, form:)
	end
end
