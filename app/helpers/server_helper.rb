# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
module ServerHelper
	#---------------------------------------------------------
	# fields for "server" pages
	#---------------------------------------------------------
	# title fields for admin pages
	def server_header(icon: Server.server_logo, subtitle: Server.server_name, form: false)
		if form
			header = title_start(icon:, title: Server.act(:edit), cols: 4)
			header << [ { kind: :text_box, key: :server_name, value: subtitle, size: 27, placeholder: Person.fld(:name), mandatory: { length: 3 }, cols: 4 } ]
		else
			title_start(icon:, title: Server.label, subtitle:)
		end
	end

	def server_show_fields
		[
			[
				button_field({ kind: :jump, symbol: symbol_hash(:icon, namespace: "sport"), url: sports_path(rdx: 0), label: Sport.label(:plural) }, align: :center),
				button_field({ kind: :jump, symbol: :rivals, url: clubs_path(rdx: 0), label: Club.label(:plural) }, align: :center),
				button_field({ kind: :jump, symbol: :calendar, url: seasons_path(rdx: 0), label: Season.label(:plural) }, align: :center)
			],
			[
				button_field({ kind: :jump, symbol: :user, url: users_path(rdx: 0), label: User.label(:plural) }, align: :center),
				button_field({ kind: :jump, symbol: :actions, url: log_server_path(rdx: 2), label: UserAction.label(:short) }, align: :center),
				button_field({ kind: :jump, symbol: :settings, url: edit_server_path(rdx: 0), label: Server.act(:configure), frame: :modal }, align: :center)
			]
		]
	end

	def server_edit_fields
		css     = "align-top ml-auto mr-2"
		fields  = server_header(form: true)
		fields += [
			[
				symbol_field(:email, { type: :button, css:, title: Server.fld(:support_email) }),
				{ kind: :email_box, key: :support_email, value: Server.support_email, placeholder: Server.fld(:support_email), cols: 4 }
			],
			[
				symbol_field(:edit, { type: :button, css:, title: Server.fld(:email_signature) }),
				{ kind: :text_area, key: :email_signature, value: Server.email_signature, placeholder: Server.fld(:email_signature), size: 27, cols: 4 }
			],
			[
				symbol_field(:locale, { css:, title: Server.fld(:default_locale) }),
				{ kind: :select_box, align: :left, key: :default_locale, options: Server.locale_list, value: Server.default_locale },
				symbol_field(:calendar, { css:, title: Server.fld(:date_format) }),
				{ kind: :select_box, align: :left, key: :date_format, options: Server.date_formats, value: Server.date_format }
			],
			gap_row,
			[
				gap_field(size: 2),
				label_field(I18n.t("shared.settings"), cols: 4)
			]
		]

		Server.boolean_option_list.each do |opt|
			fields << [
				gap_field(size: 2),
				{ kind: :label_checkbox, key: opt[1], label: opt[0], cols: 4 }
			]
		end

		fields
	end

	#---------------------------------------------------------
	# fields for modal "about" view
	#---------------------------------------------------------
	# title for "about MudClub.." view
	def server_about_header
		build = "(#{I18n.t("server.build")}#{BUILD})"
		res   = title_start(icon: "mudclub.svg", title: server_about_version)
		res  += [
			[ { kind: :string, value: build, class: "text-sm text-gray-500" } ],
			[ button_field({ kind: :link, label: I18n.t("server.about"), url: "https://github.com/iangullo/mudclub/wiki", tab: true }, cols: 2) ]
		]
	end

	# fields for "about MudClub.." view
	def server_about_fields
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

	def server_about_version
		"MudClub #{VERSION}"
	end

	#---------------------------------------------------------
	# user action log table
	#---------------------------------------------------------
	def server_actions_table(actions:, retlnk: nil)
		title = [
			{ kind: :normal, value: Event.fld(:date), align: "center" },
			{ kind: :normal, value: Club.label },
			{ kind: :normal, value: User.label },
			{ kind: :normal, value: Drill.fld(:description) }
		]

		rows = []
		actions.each { |action|
			url = action.url.present? ? action.url : "#"
			frm = action.modal ? :modal : "_top"
			row = { url:, frame: frm, items: [] }
			row[:items] << { kind: :normal, value: action.date_time }
			row[:items] << (action.user.active? ? icon_field(action.user.club.logo, title: action.user.club.nick, align: :center) : symbol_field(:no, align: :center))
			row[:items] << { kind: :normal, value: action.user.s_name }
			row[:items] << { kind: :normal, value: action.description }
			rows << row
		}
		{ title:, rows: }
	end
end
