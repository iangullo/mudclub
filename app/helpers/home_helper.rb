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
module HomeHelper
	# default title FieldComponents for home page
	def home_title(icon: current_user.picture, title: current_user.s_name, subtitle: nil)
		title_start(icon:, title:, subtitle:, _class: "rounded-full")
	end

	# title for "about MudClub.." view
	def home_about_title
		build = "(#{I18n.t("server.build")}#{BUILD})"
		res   = title_start(icon: "mudclub.svg", title: "MudClub #{VERSION}")
		res  += [
			[ { kind: :string, value: build, class: "text-sm text-gray-500" } ],
			[ button_field({ kind: :link, label: I18n.t("server.about"), url: "https://github.com/iangullo/mudclub/wiki", tab: true }, cols: 2) ]
		]
	end

	# fields for "about MudClub.." view
	def home_about
		[
			[ { kind: :string, value: I18n.t("server.info-1") } ],
			[ { kind: :string, value: I18n.t("server.info-2") } ],
			[ { kind: :string, value: bulletize(I18n.t("server.info-3")) } ],
			[ { kind: :string, value: bulletize(I18n.t("server.info-4")) } ],
			[ { kind: :string, value: bulletize(I18n.t("server.info-5")) } ],
			[ { kind: :string, value: bulletize(I18n.t("server.info-6")) } ],
			gap_row,
			[ copyright_field ],
			[ { kind: :string, value: I18n.t("server.published"), align: "right", class: "text-xs text-gray-500" } ]
		]
	end

	# title fields for admin pages
	def home_admin_title(icon: "mudclub.svg", subtitle: current_user.to_s)
		title_start(icon:, title: "MudClub - #{I18n.t("action.admin")}", subtitle:, rows: 2, _class: "rounded-full")
	end

	def home_admin
		[
			[
				button_field({ kind: :jump, symbol: symbol_hash("icon", namespace: "sport"), url: sports_path(rdx: 0), label: I18n.t("sport.many") }, align: "center"),
				button_field({ kind: :jump, symbol: "calendar", url: seasons_path(rdx: 0), label: I18n.t("season.many") }, align: "center"),
				button_field({ kind: :jump, symbol: "rivals", url: clubs_path(rdx: 0), label: I18n.t("club.many") }, align: "center")
			],
			[
				button_field({ kind: :jump, symbol: "user", url: users_path(rdx: 0), label: I18n.t("user.many") }, align: "center"),
				button_field({ kind: :jump, symbol: "actions", url: home_log_path(rdx: 0), label: I18n.t("user.actions") }, align: "center")
			]
		]
	end

	# user action log table
	def home_actions_table(actions:, retlnk: nil)
		title = [
			{ kind: :normal, value: I18n.t("calendar.date"), align: "center" },
			{ kind: :normal, value: I18n.t("club.single") },
			{ kind: :normal, value: I18n.t("user.single") },
			{ kind: :normal, value: I18n.t("drill.desc") }
		]

		rows = []
		actions.each { |action|
			url = action.url.present? ? action.url : "#"
			frm = action.modal ? "modal" : "_top"
			row = { url:, frame: frm, items: [] }
			row[:items] << { kind: :normal, value: action.date_time }
			row[:items] << (action.user.active? ? icon_field(action.user.club.logo, align: "center") : symbol_field("no", align: "center"))
			row[:items] << { kind: :normal, value: action.user.s_name }
			row[:items] << { kind: :normal, value: action.description }
			rows << row
		}
		{ title:, rows: }
	end

	# user login fields
	def home_closed
		[
			[
				symbol_field("user", { size: "30x30" }, align: "center"),
				button_field(home_login_button, rows: 2)
			],
			[
				{ kind: :text, value: I18n.t("status.closed"), align: "center" }
			]
		]
	end

	def home_login_button
		{ kind: "jump", url: new_user_session_path, data: { turbo_frame: "_top" }, symbol: symbol_hash("login", type: "button"), class: "m-2", d_class: "rounded bg-blue-900 hover:bg-blue-700 max-h-8 min-h-6" }
	end
end
