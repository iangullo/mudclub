# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
	def person_name_field(person)
		{ kind: :normal, value: person.to_s }
	end

	def person_form(person, mandatory_email: nil)
		l_nick  = person.attr(:nickname)
		l_phone = person.attr(:phone)
		l_pid   = person.attr(:national_id)
		l_email = person.attr(:email)
		l_addr  = person.attr(:address)

		res = [
			[
				symbol_field("user", { title: l_nick }),
				{ kind: :text_box, key: :nick, size: 8, value: person&.nick, placeholder: l_nick },
				gap_field,
				symbol_field("call", { title: l_phone }),
				{ kind: :text_box, key: :phone, size: 12, value: person&.phone, placeholder: l_phone }
			],
			[
				symbol_field("id_front", { title: l_pid }),
				{ kind: :text_box, key: :dni, size: 8, value: person&.dni, placeholder: l_pid },
				gap_field,
				symbol_field("email", { type: :button, title: l_email }),
				{ kind: :email_box, key: :email, value: person&.email, placeholder: l_email, mandatory: mandatory_email ? { length: 7 } : nil }
			]
		]
		if person&.coach_id? || person&.player_id?
			res << [ gap_field(size: 1), person_idpic(person, idpic: "id_front", align: "left", cols: 4) ]
			res << [ gap_field(size: 1), person_idpic(person, idpic: "id_back", align: "left", cols: 4) ]
		end
		res << [
			symbol_field("home", { size: "25x25", title: l_addr }, class: "align-top"),
			{ kind: :text_area, key: :address, size: 34, cols: 4, lines: 3, value: person&.address, placeholder: l_addr }
		]
	end

	# nested form to add/edit person relationships
	def person_relationships_form(person)
		res = [ [ { kind: :label, value: I18n.t("parent.many") } ] ]
		res << [
			{
				kind: :nested_form,
				model: "person",
				key: :relationships,
				child: -> { Relationship.build_for(person) },
				row: "people/relationships/relationship_fields",
				cols: 2
			}
		]
		res
	end

	# return defintion @fields for forms
	def person_form_title(pobj, icon: person&.picture, title:, cols: 2, sex: nil)
		person = pobj.person
		res = person_title(title:, icon:, rows: (sex ? 3 : 4), cols:, form: true)
		res << [ { kind: :text_box, key: :name, value: person&.name, placeholder: person.attr(:name), cols: 2, mandatory: { length: 2 } } ]
		res << [ { kind: :text_box, key: :surname, value: person&.surname, placeholder: person.attr(:surname), cols: 2, mandatory: { length: 2 } } ]
		res << (sex ? [ { kind: :label_checkbox, label: person.t_path(:sex, :female_short), key: :female, value: person&.female, align: "left" } ] : [])
		res.last << symbol_field("calendar")
		res.last << { kind: :date_box, key: :birthday, s_year: 1950, e_year: Time.now.year, value: person&.birthday, mandatory: true }
		res = person_participation_fields(pobj, res, just_icon: false) unless pobj.is_a?(Person)
		res
	end

	# wrapper to manage return of suitable Field for id Person fields
	# standardised field with icons for player/coach id pics
	def person_idpic(person, idpic: nil, cols: nil, align: "center")
		if idpic	# it is an editor field
			{ kind: :upload, symbol: symbol_hash(idpic, size: "20x20", css: "mr-2", title: person.attr(idpic)), label: person.attr(idpic, :short), key: idpic, value: person&.send(idpic)&.filename, cols: }
		else
			pidpic = person&.idpic_content
			symbol = pidpic[:symbol]
			label  = pidpic[:label]
			if pidpic[:found] && u_manager?	# dropdown menu
				button = { kind: :link, name: "id-pics", symbol:, label:, append: true, options: [] }
				button[:options] << idpic_button(person, "id_front") if person&.id_front.attached?
				button[:options] << idpic_button(person, "id_back") if person&.id_back.attached?
				{ kind: :dropdown, button:, class: "bg-white", cols: }
			else
				{ kind: :icon_label, symbol:, label:, right: true, align: "left", cols: }
			end
		end
	end

	# return title for @people TableComponent
	def people_table(people:)
		title = [
			{ kind: :normal, value: I18n.t("people.person.label.single") }
		]
		title << button_field({ kind: :add, url: new_person_path, frame: "modal" }) if u_admin?

		rows = Array.new
		people.each { |person|
			row = { url: person_path(person), frame: "modal", items: [] }
			row[:items] << { kind: :normal, value: person.to_s }
			row[:items] << button_field({ kind: :delete, url: row[:url], name: person.to_s }) if u_admin?
			rows << row
		}
		{ title: title, rows: rows }
	end

	# FieldComponent fields to show a person
	def person_show_fields(person, title: Person.label, icon: person&.picture)
		[
			[
			symbol_field("home", { size: "25x25", title: I18n.t("person.fields.address.label") }, class: "align-top", align: "right"),
			{ kind: :string, value: simple_format("#{@person&.address}"), align: "left" }
			]
		]
	end

	def person_show_participation_title(obj, title: nil, status_url: nil, just_icon: true, cols: nil)
		icon     = obj.picture
		title  ||= obj.kind_label
		subtitle = obj.to_s

		fields = person_title(icon:, title:, subtitle:, cols:)
		fields = person_participation_fields(obj, fields, status_url:, just_icon:)

		fields << [
			{ kind: :string, value: date_string(obj&.birthday), class: "items-center" },
			gap_field,
			{ kind: :contact, email: obj&.email, phone: obj&.phone, device: device, align: "left", cols: 3 }
		]
	end

	def person_participation_fields(obj, fields, status_url: nil, just_icon: true)
		fields[0] += [
			gap_field,
			obj_club_field(obj, align: :left),
			gap_field,
			obj_kind_field(obj, align: :right)
		]
		fields[1] += [
			gap_field,
			obj_status_field(obj, status_url:, just_icon:, f_opts: { align: :left, cols: 3 })
		]
		fields
	end

	# fields definition to show title of a person view
	def person_show_title(pobj, title: nil, kind: nil, rows: 3, cols: nil)
		owned  = !pobj.is_a?(Person)
		person = owned ? pobj.person : pobj

		icon     = pobj.picture
		title  ||= pobj.label
		subtitle = person&.nick&.presence || person&.name

		fields = person_title(icon:, title:, subtitle:, rows:, cols:)
		fields += [
			[ { kind: :label, value: person&.surname, cols: } ],
			[
				{ kind: :string, value: date_string(person&.birthday), class: "items-center", cols: },
				{ kind: :contact, email: person&.email, phone: pobj&.phone, device: device, align: "center" }
			],
			[ gap_field,  person_idpic(person) ]
		]
		if owned
			fields[4][0] = obj_club_field(pobj)
		end
		fields
	end

	# return icon and top of fields definition
	def person_title(icon: symbol_hash("person"), title:, subtitle: nil, rows: 3, cols: nil, size: "75x100", _class: "max-w-75 max-h-100 rounded align-top m-1", form: nil)
		title_start(icon:, title:, subtitle:, rows:, cols:, size:, _class: _class, form:)
	end

	private
		# button to download an idpic
		def idpic_button(person, idpic)
			{
				kind: :link,
				label: person.attr(idpic.to_sym, :short),
				url: rails_blob_path(person&.send(idpic), disposition: "attachment"),
				d_class: "inline-flex items-center"
			}
		end
end
