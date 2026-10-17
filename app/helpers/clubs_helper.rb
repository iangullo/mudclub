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
	# public mode fields
	def club_public_fields
		[ [ label_item("#{Team.label(:plural)} - #{@season.name}") ] ]
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
	def club_links
		if @policy.show_details?	# user's club
			opt = { status: :active }
			res = [ [
				normal_button({ kind: :jump, symbol: :board_member, url: club_assignments_path(@club, kind: :board_members, **opt), label: Membership.kind_label(:board_member, :plural) }, align: :center),
				normal_button({ kind: :jump, symbol: :team, url: club_teams_path(@club), label: Team.label(:plural) }, align: :center),
				normal_button({ kind: :jump, symbol: :timetable, url: club_slots_path(@club), label: Slot.label(:plural) }, align: :center)
			] ]

			if @policy.manage_members?
				res << [
					normal_button({ kind: :jump, symbol: :athlete, url: club_members_path(@club, kind: :athletes, **opt), label: Sport.term(:athlete, :plural) }, align: :center),
					normal_button({ kind: :jump, symbol: :coach, url: club_members_path(@club, kind: :coaches, **opt), label:  Sport.term(:coach, :plural) }, align: :center),
					normal_button({ kind: :jump, symbol: :registration, url: club_registrations_path(@club), label:  Registration.label(:plural) }, align: :center)
				]
			end

			res << [
				normal_button({ kind: :jump, symbol: :location, url: club_locations_path(@club), label: Location.label(:plural) }, align: :center),
				normal_button({ kind: :jump, symbol: :rivals, url: clubs_path(@club), label: Club.fld(:rivals) }, align: :center)
			]
			res.last << normal_button({ kind: :jump, symbol: :document, url: club_documents_path(@club), label: Document.label(:plural) }, align: :center) if @policy.manage_documents?

			res << []
		else
			res = [ [
				normal_button({ kind: :jump, symbol: :team, url: club_teams_path(@club), label: Team.label(:plural) }, align: :center),
				normal_button({ kind: :jump, symbol: :location, url: club_locations_path(@club), label: Location.label(:plural) }, align: :center)
			] ]
		end
		res
	end

	# return Club definition @fields for forms
	def club_form(cols: 5)
		css = "align-top"
		[
			[
				symbol_item(:website, { css: }),
				{ kind: :text_box, key: :website, value: @club.website, placeholder: Club.fld(:website), size: 33, cols: }
			],
			[
				symbol_item(:call, { css: }),
				{ kind: :text_box, key: :phone, size: 12, value: @club.phone, placeholder: @club.fld(:phone) },
				symbol_item(:locale, { css:, title: I18n.t("shared.fields.language") }),
				{ kind: :text_box, align: "left", key: :country, value: @club.country, placeholder: "US", size: 2, mandatory: { length: 2 } },
				symbol_item(:flag, { css:, title: I18n.t("shared.fields.country") }),
				{ kind: :select_box, align: "left", key: :locale, options: User.locale_list, value: @club.locale }
			],
			[
				symbol_item(:email, { type: :button, css: }),
				{ kind: :email_box, key: :email, value: @club.email, placeholder: @club.fld(:email), size: 33, cols: }
			],
			[
				symbol_item(:home, { css: }),
				{ kind: :text_area, key: :address, size: 30, cols:, lines: 3, value: @club.address, placeholder: Person.fld(:address) }
			]
		]
	end

	def club_header(icon: @club&.logo, title: @club&.nick, form: nil)
		icon  ||= "mudclub.svg"
		title ||= Club.label
		size    = (icon.is_a?(Hash) && icon[:concept] == :rivals) ? nil : "75x100"
		header  = title_start(icon:, title:, size:, rows: 3, cols: 2, form:)
		if form
			header << [ { kind: :text_box, key: :nick, value: @club.nick, placeholder: @club.fld(:name), cols:, mandatory: { length: 3 } } ]
			header << [ { kind: :text_box, key: :name, value: @club.name, size: 27, placeholder: @club.fld(:entity), cols:, mandatory: { length: 3 } } ]
		else
			header << [ { kind: :string, value: @club.name, cols: 2 } ]
			header << [ { kind: :contact, website: @club.website, phone: @club.phone, email: @club.email, device: device } ]
		end
	end
end
