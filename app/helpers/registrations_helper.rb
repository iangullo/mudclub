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
module RegistrationsHelper
	def registration_header(registration = @registration, action: :show)
		icon     = registration.club&.logo || "mudclub.svg"
		title    = registration.club&.nick || Server.server_name
		case action
		when :index
			subtitle = Registration.label(:plural)
		when :show
			subtitle = "#{Registration.label} #{registration.s_name}"
		else
			subtitle = @team ? @team.to_s : Registration.act(action)
		end
		header = title_start(icon:, title:, subtitle:)
		header << [
			symbol_field(:athlete, { title: registration.kind_label }, align: :center),
			{ kind: :label, value: Registration.act(action) }
		] if @team

		header
	end

	# fields to show when looking a registration request
	def registration_show_fields(registration = @registration)
		fields = [
			[	gap_field(size: 0), { kind: :label, value: registration.s_name } ],
			[]
		]

		fields
	end

	def registration_form_header(registration = @registration, action: :edit)
		header = person_form_title(
				registration,
				icon: registration.candidate,
				title: registration.act(action),
				sex: true
			)
		header
	end

	def registration_requester_form_fields(registration = @registration, action: :edit)
		l_email   = Person.fld(:email)
		l_phone   = Person.fld(:phone)
		requester = registration.requester || AdmissionPerson.new
		[
			[
				{ kind: :text_box, key: :name, value: requester.name, placeholder: Person.fld(:name), mandatory: { length: 2 }, size: 14, cols: 2 },
				gap_field(size: 1),
				{ kind: :text_box, key: :surname, value: requester.surname, placeholder: Person.fld(:surname), mandatory: { length: 2 }, size: 19, cols: 2 }
			],
			[
				symbol_field(:call, { type: :button, title: l_phone }, class: "inline-flex"),
				{ kind: :text_box, key: :email, value: requester.phone, placeholder: l_phone, mandatory: { length: 7 }, size: 12 },
				gap_field(size: 1),
				symbol_field(:email, { type: :button, title: l_email }, align: :right, class: "inline-flex"),
				{ kind: :email_box, key: :email, value: requester.email, placeholder: l_email, mandatory: { length: 7 } }
			]
		]
	end

	def registration_form_fields(registration = @registration, action: :show)
		fields  = [ gap_row(cols: 5) ]
		fields += [
			[
				gap_field(size: 0),
				{ kind: :string, value: "*Document management?", cols: 4 }
			],
			[
				gap_field(size: 0),
				{ kind: :string, value: "*requester kind???", cols: 4 }
			],
			[
				gap_field(size: 0),
				{ kind: :string, value: "Requester???", cols: 4 }
			]
		]

		fields
	end

	# fields to show when looking a user profile
	def registration_status_form_fields(registration = @registration)
	end

	# return table for @registrations TableComponent definition
	def registration_table(registrations = @registrations)
		{
			title: registrations_table_header,
			rows: registrations_table_rows(registrations)
		}
	end

	# return registration TableComponent definition
	def registration_history_table(registration = @registration)
	end

	private
	def registrations_table_header
		title = @clubs ?
			[ { kind: :normal, value: Club.label, align: :center } ]:
			[]

		title += [
			{ kind: :normal, value: Team.label },
			{ kind: :normal, value: Registration.fld(:kind) },
			{ kind: :normal, value: Person.fld(:name) },
			{ kind: :normal, value: Registration.fld(:status) },
			{ kind: :normal, value: Registration.fld(:updated_at) }
		]
	end

	def registrations_table_rows(registrations)
		rows = []

		registrations.each do |reg|
			row = { url: path_for(reg), items: [] }
			if @clubs
				row[:items] << icon_field(reg.club.logo, title: reg.club.nick, align: :center)
			end

			row[:items] << { kind: :normal, value: reg.team ? reg.team.name : "-" }

			row[:items] += [
				{ kind: :normal, value: reg.kind_label },
				{ kind: :normal, value: "#{reg.candidate_name} #{reg.candidate_surname}" },
				{ kind: :normal, value: I18n.t("admissions.registration_statuses.values#{reg.status}.single") }
			]
		end

		rows
	end
end
