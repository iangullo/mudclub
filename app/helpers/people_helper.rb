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
	# Multipurpose person title definition
	def person_title(icon: symbol_hash("person"), title:, subtitle: nil, rows: 3, cols: nil, size: "75x100", _class: "max-w-75 max-h-100 rounded align-top m-1", form: nil)
		title_start(icon:, title:, subtitle:, rows:, cols:, size:, _class: _class, form:)
	end

	#----------------------------------------------
	# Field definitions for person show
	#----------------------------------------------
	def person_show_title(pobj, title: nil, rows: 3, cols: nil, id_pic: true)
		owned  = !pobj.is_a?(Person)
		person = owned ? pobj.person : pobj

		icon     = pobj.picture
		title  ||= pobj.label
		subtitle = person&.nick&.presence || person&.name

		fields = person_title(icon:, title:, subtitle:, rows:, cols:)

		c_field = person&.email || pobj&.phone ?
			{ kind: :contact, email: person&.email, phone: pobj&.phone, device:, align: :left } :
			{ kind: :text, value: Person.msg(:no_contact) }

		id_field = id_pic ?
			person_idpic(person) :
			{ kind: :string, value: pobj&.person&.dni || Person.msg(:no_id) }

		fields += [
			[ label_field(person&.surname, cols:) ],
			[
				{ kind: :string, value: date_string(person&.birthday), class: "items-center", cols: },
				c_field
			],
			[ gap_field, id_field ]
		]
		if owned
			fields[4][0] = participation_club_field(pobj)
		end
		fields
	end

	# FieldComponent fields to show a person
	def person_show_fields(person, title: Person.label, icon: person&.picture)
		[
			[
			symbol_field("home", { size: "25x25", title: Person.fld(:address) }, class: "align-top", align: "right"),
			{ kind: :string, value: simple_format("#{@person&.address}"), align: "left" }
			]
		]
	end

	#----------------------------------------------
	# Field definitions for person forms
	#----------------------------------------------
	def person_form_title(pobj, icon: person&.picture, title:, cols: 2, sex: nil)
		person = pobj.person
		res = person_title(title:, icon:, rows: (sex ? 3 : 4), cols:, form: true)
		res << [ { kind: :text_box, key: :name, value: person&.name, placeholder: Person.fld(:name), cols: 2, mandatory: { length: 2 } } ]
		res << [ { kind: :text_box, key: :surname, value: person&.surname, placeholder: Person.fld(:surname), cols: 2, mandatory: { length: 2 } } ]
		res << (sex ? [ { kind: :label_checkbox, label: Person.t_path(:sex, :female_short), key: :female, value: person&.female, align: "left" } ] : [])
		res.last << symbol_field(:calendar)
		res.last << { kind: :date_box, key: :birthday, s_year: 1950, e_year: Time.now.year, value: person&.birthday, mandatory: true }
		res = participation_fields(pobj, res, just_icon: false) unless pobj.is_a?(Person)
		res
	end

	def person_form_fields(person, mandatory_email: nil)
		l_nick  = Person.fld(:nickname)
		l_phone = Person.fld(:phone)
		l_pid   = Person.fld(:national_id, :short)
		l_email = Person.fld(:email)
		l_addr  = Person.fld(:address)

		res = [
			[
				symbol_field(:user, { title: l_nick }),
				{ kind: :text_box, key: :nick, size: 8, value: person&.nick, placeholder: l_nick },
				gap_field,
				symbol_field(:call, { title: l_phone }),
				{ kind: :text_box, key: :phone, size: 12, value: person&.phone, placeholder: l_phone }
			],
			[
				symbol_field(:id_front, { title: l_pid }),
				{ kind: :text_box, key: :dni, size: 8, value: person&.dni, placeholder: l_pid },
				gap_field,
				symbol_field(:email, { type: :button, title: l_email }),
				{ kind: :email_box, key: :email, value: person&.email, placeholder: l_email, mandatory: mandatory_email ? { length: 7 } : nil }
			]
		]
		if person.is_a?(AdmissionPerson) || person&.coach_id? || person&.player_id?
			res << [ gap_field(size: 1), person_idpic(person, idpic: :id_front, align: :left, cols: 4) ]
			res << [ gap_field(size: 1), person_idpic(person, idpic: :id_back, align: :left, cols: 4) ]
		end
		res << [
			symbol_field(:home, { size: "25x25", title: l_addr }, class: "align-top"),
			{ kind: :text_area, key: :address, size: 34, cols: 4, lines: 3, value: person&.address, placeholder: l_addr }
		]
	end

	# nested form to add/edit person relationships
	def person_relationships_form(person)
		res = [ [ label_field(Relationship.label(:plural)) ] ]
		res << [
			{
				kind: :nested_form,
				model: "person",
				key: :relationships,
				child: -> { Relationship.build_for(person) },
				row: "shared/relationship_fields",
				cols: 2
			}
		]
		res
	end

	# nested form to add/edit person relationships
	def person_merge_fields(pobj, candidates, attrs)
		# Pass original form fields as hidden data to rebuild the object
		pobj_fields = []
		hidden_field_definitions(attrs).each { |field| pobj_fields << field }

		merge_fields = [ pobj_fields ]
		merge_fields += [
			gap_row,
			[ label_field(Person.msg(:ambiguous)) ]
		]

		lastopt = { value: lastopt, label: Person.act(:create) }
		options = []
		candidates.each do |candidate|
			if candidate == pobj.person
				lastopt = { value: "__keep__", label: Person.act(:keep) } if pobj.person.persisted?
			else
				options << { person: candidate, value: candidate.id, label: "#{candidate} (#{candidate.age})" }
			end
		end

		options << lastopt

		merge_fields << [
			{ kind: :radio_group, key: :person_merge, value: lastopt[:value], options: }
		]
	end

	private
		# button to download an idpic
		def idpic_button(person, idpic)
			{
				kind: :link,
				label: Person.fld(idpic.to_sym, :short),
				url: rails_blob_path(person&.send(idpic), disposition: "attachment"),
				d_class: "inline-flex items-center"
			}
		end

		# wrapper to manage return of suitable Field for id Person fields
		# standardised field with icons for player/coach id pics
		def person_idpic(person, idpic: nil, cols: nil, align: "center")
			if idpic	# it is an editor field
				{ kind: :upload, symbol: symbol_hash(idpic, size: "20x20", css: "mr-2", title: Person.fld(idpic)), label: Person.fld(idpic, :short), key: idpic, value: person&.send(idpic)&.filename, cols: }
			else
				pidpic = person&.idpic_content
				symbol = pidpic[:symbol]
				label  = pidpic[:label]
				if pidpic[:found] && @policy.update?	# dropdown menu
					button = { kind: :link, name: "id-pics", symbol:, label:, append: true, options: [] }
					button[:options] << idpic_button(person, "id_front") if person&.id_front.attached?
					button[:options] << idpic_button(person, "id_back") if person&.id_back.attached?
					{ kind: :dropdown, button:, class: "bg-white", cols: }
				else
					{ kind: :icon_label, symbol:, label:, right: true, align: "left", cols: }
				end
			end
		end
end
