# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
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
module PeopleHelper
	def person_form_fields(person, mandatory_email: nil)
		res = [
			[
				symbol_field("user", { title: I18n.t("person.nick") }),
				{ kind: :text_box, key: :nick, size: 8, value: person&.nick, placeholder: I18n.t("person.nick") },
				gap_field,
				symbol_field("call", { title: I18n.t("person.phone") }),
				{ kind: :text_box, key: :phone, size: 12, value: person&.phone, placeholder: I18n.t("person.phone") }
			],
			[
				symbol_field("id_front", { title: I18n.t("person.pid") }),
				{ kind: :text_box, key: :dni, size: 8, value: person&.dni, placeholder: I18n.t("person.pid") },
				gap_field,
				symbol_field("email", { type: :button, title: I18n.t("person.email") }),
				{ kind: :email_box, key: :email, value: person&.email, placeholder: I18n.t("person.email"), mandatory: mandatory_email ? { length: 7 } : nil }
			]
		]
		if person&.coach_id? || person&.player_id?
			res << [ gap_field(size: 1), idpic_field(person, idpic: "id_front", align: "left", cols: 4) ]
			res << [ gap_field(size: 1), idpic_field(person, idpic: "id_back", align: "left", cols: 4) ]
		end
		res << [
			symbol_field("home", { size: "25x25", title: I18n.t("person.address") }, class: "align-top"),
			{ kind: :text_area, key: :address, size: 34, cols: 4, lines: 3, value: person&.address, placeholder: I18n.t("person.address") }
		]
	end

	# return FieldsComponent @fields for forms
	def person_form_title(person, icon: person&.picture, title:, cols: 2, sex: nil)
		res = person_title_fields(title:, icon:, rows: (sex ? 3 : 4), cols:, form: true)
		res << [ { kind: :text_box, key: :name, value: person&.name, placeholder: I18n.t("person.name"), cols: 2, mandatory: { length: 2 } } ]
		res << [ { kind: :text_box, key: :surname, value: person&.surname, placeholder: I18n.t("person.surname"), cols: 2, mandatory: { length: 2 } } ]
		res << (sex ? [ { kind: :label_checkbox, label: I18n.t("sex.female_a"), key: :female, value: person&.female, align: "left" } ] : [])
		res.last << symbol_field("calendar")
		res.last << { kind: :date_box, key: :birthday, s_year: 1950, e_year: Time.now.year, value: person&.birthday, mandatory: person&.player_id? }
		res
	end

	# return title for @people TableComponent
	def person_table
		title = [ { kind: :normal, value: I18n.t("person.name") } ]
		title << button_field({ kind: :add, url: new_person_path, frame: "modal" }) if u_admin?

		rows = Array.new
		@people.each { |person|
			row = { url: person_path(person), frame: "modal", items: [] }
			row[:items] << { kind: :normal, value: person.to_s }
			row[:items] << button_field({ kind: :delete, url: row[:url], name: person.to_s }) if u_admin?
			rows << row
		}
		{ title: title, rows: rows }
	end

	# FieldComponent fields to show a person
	def person_show_fields(person, title: I18n.t("person.single"), icon: person&.picture, rows: 3, cols: 2)
		res = person_title_fields(title:, icon:, rows:, cols:)
		res << [ { kind: :label, value: person&.nick&.presence || person&.name, cols: } ]
		res << [ { kind: :label, value: person&.surname, cols: } ]
		res << [ gap_field(size: 0), { kind: :string, value: person&.birthstring } ]
		res << [ { kind: :contact, email: person&.email, phone: person&.phone, device: device, align: "center" } ]
		res.last << idpic_field(person) if person&.coach_id? || person&.player_id?
		res << [
			symbol_field("home", { size: "25x25", title: I18n.t("person.address") }, class: "align-top", align: "right"),
			{ kind: :string, value: simple_format("#{person&.address}"), align: "left", cols: 2 }
		] if person&.address&.present?
		res
	end

	# return icon and top of FieldsComponent
	def person_title_fields(title:, icon: symbol_hash("person"), rows: 2, cols: nil, size: "75x100", _class: "max-w-75 max-h-100 rounded align-top m-1", form: nil)
		title_start(icon:, title:, rows:, cols:, size:, _class: _class, form:)
	end

	private
		# button to download an idpic
		def idpic_button(person, idpic)
			{
				kind: :link,
				label: I18n.t("person.#{idpic}"),
				url: rails_blob_path(person&.send(idpic), disposition: "attachment"),
				d_class: "inline-flex items-center"
			}
		end

		# wrapper to manage return of suitable Field for dni Person fields
		# standardised field with icons for player/coach id pics
		def idpic_field(person, idpic: nil, cols: nil, align: "center")
			if idpic	# it is an editor field
				{ kind: :upload, symbol: symbol_hash(idpic, size: "20x20", css: "mr-2", title: I18n.t("person.pid")), label: I18n.t("person.#{idpic}"), key: idpic, value: person&.send(idpic)&.filename, cols: }
			else
				pidpic = person&.idpic_content
				symbol = pidpic[:symbol]
				label  = pidpic[:label]
				if pidpic[:found] && u_manager?	# dropdown menu
					button = { kind: :link, name: "id-pics", symbol:, label:, append: true, options: [] }
					button[:options] << idpic_button(person, "id_front") if person&.id_front.attached?
					button[:options] << idpic_button(person, "id_back") if person&.id_back.attached?
					{ kind: :dropdown, button:, class: "bg-white" }
				else
					{ kind: :icon_label, symbol:, label:, right: true, align: "left" }
				end
			end
		end
end
