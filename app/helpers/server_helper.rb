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
				normal_button({ kind: :jump, symbol: symbol_hash(:icon, namespace: "sport"), url: sports_path(rdx: 0), label: Sport.label(:plural) }, align: :center),
				normal_button({ kind: :jump, symbol: :rivals, url: clubs_path(rdx: 0), label: Club.label(:plural) }, align: :center),
				normal_button({ kind: :jump, symbol: :calendar, url: seasons_path(rdx: 0), label: Season.label(:plural) }, align: :center)
			],
			[
				normal_button({ kind: :jump, symbol: :user, url: users_path(rdx: 0), label: User.label(:plural) }, align: :center),
				normal_button({ kind: :jump, symbol: :actions, url: log_server_path(rdx: 2), label: UserAction.label(:short) }, align: :center),
				normal_button({ kind: :jump, symbol: :settings, url: edit_server_path(rdx: 0), label: Server.act(:configure), frame: :modal }, align: :center)
			]
		]
	end

	# Fixed Server edit view content header
	def server_edit_header(form: false)
		server_header(form: true)
	end

	def server_edit_accordion(form: nil)
		objects = [
			{ head: Server.fld(:localization_section), rows: server_localization_section },
			{ head: Server.fld(:visibility_section),   rows: server_visibility_section },
			{ head: Server.fld(:modules_section),      rows: server_modules_section }
		].map do |s|
			content = FieldsComponent.new(s[:rows])
			content.form = form if form
			{ head: s[:head], content: }
		end
		{ title: Server.act(:configure), objects:, form: }
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
			[ normal_button({ kind: :link, label: I18n.t("server.about"), url: "https://github.com/iangullo/mudclub/wiki", tab: true }, cols: 2) ]
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
			[ copyright_item ],
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
			row[:items] << (action.user.active? ? icon_item(action.user.club.logo, title: action.user.club.nick, align: :center) : symbol_item(:no, align: :center))
			row[:items] << { kind: :normal, value: action.user.s_name }
			row[:items] << { kind: :normal, value: action.description }
			rows << row
		}
		{ title:, rows: }
	end

	private
		def server_localization_section
			css = "items-top px-1"
			[
				[ { kind: :icon, symbol: symbol_hash(:locale, title: Server.fld(:default_locale)), class: css },
					{ kind: :select_box, key: :default_locale,
						options: Server.locale_list, value: Server.default_locale, i_class: "#{css} mb-2" },
					{ kind: :icon, symbol: symbol_hash(:calendar, title: Server.fld(:date_format)), class: css },
					{ kind: :select_box, key: :date_format, i_class: css,
						options: Server.date_formats, value: Server.date_format } ],
				[ { kind: :icon, symbol: symbol_hash(:time, title: Server.fld(:time_zone)), class: css },
					{ kind: :select_box, key: :time_zone, cols: 3, i_class: "#{css} mb-2",
						options: Server.time_zone_list, value: Server.time_zone } ]
			]
		end

		def server_visibility_section
			[
				[ gap_item(2),
					{ kind: :label_checkbox, key: :public_clubs_enabled,
						label: Server.fld(:public_clubs_enabled), cols: 4 } ],
				[ gap_item(2),
					{ kind: :label_checkbox, key: :public_directory_enabled,
						label: Server.fld(:public_directory_enabled), cols: 4 } ]
			]
		end

		def server_modules_section
			fields = [
				# Hidden de seguridad para uncheck-all (ya lo tienes)
				[ { kind: :hidden, name: "server[enabled_modules][]", value: "" } ]
			]

			Server.optional_modules.each do |mod|
				fields << [
					{ kind: :label_checkbox, key: :enabled_modules, value: mod.to_s,
						multiple: true, label: I18n.t("core.modules.values.#{mod}"), cols: 2,
						i_data: {
							optional_fields_target: "switch",
							optional_target:        mod.to_s,
							action:                 "change->optional-fields#toggle"
						} }
				]

				fields.concat(module_settings(mod))
			end
			fields
		end

		def module_settings(mod)
=begin
			# TODO: NOT yet ready to allow this in production.
			# need to understand first implications of each section
			fields =
				case mod.to_sym
				# How can simplify configuration & integration of the
				# SMTP infrastructure for the Server and/or each Club.
				when :mailer
					placeholder = [ Server.server_name, Server.support_email ].compact.join(" — ")
					[
						module_options_items(:email_box, :email_from, symbol: :email),
						module_options_items(:email_box, :email_reply_to, symbol: :email),
						module_options_items(:text_area, :email_signature, placeholder:, symbol: :edit)
					]

				# Think and design this correctly. Seems like registration terms
				# and privacy acceptance belong in the domain of clubs, not the server.
				when :admissions
					[
						module_options_items(:label_checkbox, :registrations_require_terms, symbol: :registration),
						module_options_items(:text_box, :registrations_terms_url, symbol: :website),
						module_options_items(:text_box, :registrations_privacy_url, symbol: :lock)
					]
				else
					[]
				end

			return [] if fields.empty?

			[ [ # single row, single cell
				{
					kind:         :optional_section,
					name:         mod.to_s,
					cols:         4,
					hidden_start: !Server.module_enabled?(mod),
					fields:       fields
				}
			] ]
=end
			[]	# TODO: remove once we figure out what to do with this section
		end

		def module_options_items(kind, key, symbol: nil, placeholder: Server.send(key).presence || Server.fld(key), size: 30)
			value = Server.settings[key]
			label = Server.fld(key) if kind == :label_checkbox
			[
				symbol ? symbol_item(symbol, { size: "25x25", css: "ml-2" }) : gap_item,
				{ kind:, key:, label:, value:, placeholder:, size: }
			]
		end
end
