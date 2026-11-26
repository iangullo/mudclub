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
module ClubsHelper
	# Club view headers
	def club_header(icon: @club&.logo, title: @club&.nick, form: nil)
		icon  ||= "mudclub.svg"
		title ||= Club.label
		size    = (icon.is_a?(Hash) && icon[:concept] == :rivals) ? nil : "75x100"
		header  = title_start(icon:, title:, size:, rows: 3, cols: 2, form:)
		if form
			header << [ { kind: :text_box, key: :nick, value: @club.nick, placeholder: @club.fld(:name), cols: 2, mandatory: { length: 3 } } ]
			header << [ { kind: :text_box, key: :name, value: @club.name, size: 27, placeholder: @club.fld(:entity), cols: 2, mandatory: { length: 3 } } ]
		else
			t_sub = [ { kind: :label, value: "#{Team.label(:plural)} (#{@season&.name})" } ]
			header << [ { kind: :string, value: @club.name, cols: 2 } ]
			if controller_name == "teams" && action_name == "index"
				header << t_sub
			elsif !current_user
				header[1] = t_sub
			else
				header << [ { kind: :contact, website: @club.website, phone: @club.phone, email: @club.email, device: device } ]
			end
		end
		header
	end

	# return @clubs TableComponent
	def club_table(clubs: @clubs)
		title = [
			{ kind: :normal, value: Club.fld(:logo) },
			{ kind: :normal, value: Person.fld(:name) },
			{ kind: :normal, value: Person.fld(:contact) }
		]
		title << normal_button({ kind: :add, url: new_club_path, frame: :modal }) if @policy.new?

		rows = Array.new
		clubs.each { |club|
			row = { url: club_path(club), items: [] }
			row[:items] += [
				icon_item(club.logo, align: :center),
				{ kind: :normal, value: club.nick },
				{ kind: :contact, phone: club.phone, email: club.email, device: device }
			]
			row[:items] << normal_button({ kind: :delete, url: row[:url], name: club.to_s, align: :left }) if @policy.destroy?
			rows << row
		}
		{ title:, rows: }
	end

	# FieldComponent fields for club links
	# FieldComponent fields for club links
	def club_links
		opt = { status: :active }

		# Row 1: Club Structure & Leadership (Board -> Teams -> Coaches)
		row_1 = []
		row_1 << club_jump_btn(:board_member, club_assignments_path(@club, kind: :board_members, **opt), Membership.kind_label(:board_member, :plural)) if @policy.show_details?
		row_1 << club_jump_btn(:team, club_teams_path(@club), Team.label(:plural))
		row_1 << club_jump_btn(:coach, club_members_path(@club, kind: :coaches, **opt), Sport.term(:coach, :plural)) if @policy.show_details? && @policy.view_coaches?

		# Row 2: Operations & Roster (Locations -> Slots -> Athletes -> Registrations)
		# Note: Placing Athletes 3rd aligns it directly beneath Coaches in Row 1
		row_2 = [
			club_jump_btn(:location, club_locations_path(@club), Location.label(:plural))
		]
		if @policy.show_details?
			row_2 << club_jump_btn(:timetable, club_slots_path(@club), Slot.label(:plural))
			row_2 << club_jump_btn(:athlete, club_members_path(@club, kind: :athletes, **opt), Sport.term(:athlete, :plural)) if @policy.view_athletes?
		end

		# Row 3: Governance & Rivals (Managers / Board only)
		row_3 = []
		if @policy.show_details?
			row_3 << club_jump_btn(:rivals, clubs_path(@club), Club.fld(:rivals)) if @policy.index?
			row_3 << club_jump_btn(:document, club_documents_path(@club), Document.label(:plural)) if @policy.view_documents?
		end

		if @policy.accepts_registrations? && (!@policy.show_details? || @policy.manage_members?)
			row_3 << club_jump_btn(:registration, club_registrations_path(@club), Registration.label(:plural))
		end

		# For public visitors (show_details? == false), merge Row 1 & Row 2 into a single compact row
		rows = @policy.show_details? ? [ row_1, row_2, row_3 ] : [ row_1 + row_2 ]

		rows.reject(&:empty?).flat_map { |row| row.each_slice(4).to_a }
	end

	def club_edit_accordion(form: nil)
		objects = [
			{ head: Person.fld(:contact),            rows: club_contact_section },
			{ head: Server.fld(:locale),             rows: club_localization_section },
			{ head: Server.fld(:visibility_section), rows: club_visibility_section },
			{ head: Server.fld(:modules_section),    rows: club_modules_section }
		].map do |s|
			content = FieldsComponent.new(s[:rows])
			content.form = form if form
			{ head: s[:head], content: }
		end
		{ title: Club.act(:configure), objects:, form: }
	end

	private
		# Localization section: locale / country / date_format / time_zone
		# The three server-inheritable selects use "" as the "inherit" option —
		# @club.settings[:key] is nil when unset, so the blank option is selected.
		def club_localization_section
			css     = "items-top px-1"
			inherit = [ Club.fld(:inherit_from_server), "" ]
			[
				[ { kind: :icon, symbol: symbol_hash(:locale, title: Club.fld(:locale)), class: css },
					{ kind: :select_box, key: :locale, options: Server.locale_list,
						value: @club.settings[:locale], i_class: "#{css} mb-2" },
					{ kind: :icon, symbol: symbol_hash(:flag, title: Club.fld(:country)), class: css },
					{ kind: :text_box, key: :country, value: @club.settings[:country],
						placeholder: "ES", size: 2, mandatory: { length: 2 }, i_class: "#{css} mb-2" } ],
				[ { kind: :icon, symbol: symbol_hash(:calendar, title: Club.fld(:date_format)), class: css },
					{ kind: :select_box, key: :date_format, i_class: css,
						options: inherit + Server.date_formats,
						value: @club.settings[:date_format] },
					{ kind: :icon, symbol: symbol_hash(:time, title: Club.fld(:time_zone)), class: css },
					{ kind: :select_box, key: :time_zone, cols: 1, i_class: "#{css} mb-2",
						options: inherit + Server.time_zone_list,
						value: @club.settings[:time_zone] } ]
			]
		end

		# Contact section: website / phone / email / address
		def club_contact_section
			css = "align-top"
			[
				[ symbol_item(:website, { css: }),
					{ kind: :text_box, key: :website, value: @club.settings[:website],
						placeholder: Club.fld(:website), size: 33, cols: 4 } ],
				[ symbol_item(:call, { css: }),
					{ kind: :text_box, key: :phone, size: 12, value: @club.phone,
						placeholder: Person.fld(:phone) },
					symbol_item(:email, { type: :button, css: }),
					{ kind: :email_box, key: :email, value: @club.email,
						placeholder: Person.fld(:email), size: 33, cols: 2 } ],
				[ symbol_item(:home, { css: }),
					{ kind: :text_area, key: :address, size: 30, cols: 4, lines: 3,
						value: @club.address, placeholder: Person.fld(:address) } ]
			]
		end

		def club_jump_btn(symbol, url, label)
			normal_button({ kind: :jump, symbol:, url:, label: }, align: :center)
		end

		# Visibility: public + optional public_directory_listed, gated by Server
		def club_visibility_section
			rows = [
				[ gap_item(2),
					{ kind: :label_checkbox, key: :public,
						label: Club.fld(:public), cols: 4 } ]
			]

			if Server.public_directory_enabled?
				rows << [ gap_item(2),
					{ kind: :label_checkbox, key: :public_directory_listed,
						label: Club.fld(:public_directory_listed), cols: 4 } ]
			end

			unless Server.public_clubs_enabled?
				rows << [ { kind: :string,
					value: Club.msg(:public_disabled_by_server),
					class: "text-xs italic text-gray-500" } ]
			end

			rows
		end

		# Modules: hidden uncheck-all guard + discovery hint + checkboxes
		def club_modules_section
			fields = [
				[ { kind: :hidden, name: "club[enabled_modules][]", value: "" } ]
			]

			offerable = Club.offerable_modules
			if offerable.empty?
				fields << [
					{
						kind: :string,
						value: I18n.t("core.modules.messages.none_available"),
						class: "text-sm italic text-gray-500"
					}
				]
				return fields
			end

			offerable.each do |mod|
				fields << [
					{ kind: :label_checkbox, key: :enabled_modules, value: mod.to_s,
						multiple: true, label: I18n.t("core.modules.values.#{mod}"), cols: 2,
						i_data: {
							optional_fields_target: "switch",
							optional_target:        mod.to_s,
							action:                 "change->optional-fields#toggle"
						} }
				]
				fields.concat(club_module_settings(mod))
			end

			fields
		end

		# Placeholder for future per-module club settings (mirrors server side)
		def club_module_settings(_mod)
			[]
		end
end
