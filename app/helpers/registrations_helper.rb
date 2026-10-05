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
			gap_field(size: 0), { kind: :label, value: Registration.act(action) }
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

	# fields to show when looking a user profile
	def registration_form_fields(registration = @registration, action: :show)
		fields  = [ gap_row(cols: 5) ]
		fields += [
			[
				symbol_field(:athlete, { title: registration.kind_label }),
				{ kind: :label, value: registration.kind_label, cols: 3 }
			],
			[
				gap_field(size: 0),
				{ kind: :text_box, key: :candidate_name, value: registration.candidate_name, placeholder: Person.fld(:name), mandatory: { length: 2 } },
				gap_field(size: 1),
				symbol_field(:calendar, { title: Person.fld(:birthday) }),
				{ kind: :date_box, key: :birthday, s_year: 1950, e_year: Time.now.year, value: registration.candidate_birthday, mandatory: true }
			],
			[
				gap_field(size: 0),
				{ kind: :text_box, key: :candidate_surname, value: registration.candidate_surname, placeholder: Person.fld(:surname), mandatory: { length: 2 } },
				gap_field(size: 1),
				symbol_field(:id_front, { title: Person.fld(:national_id) }),
				{ kind: :text_box, key: :candidate_dni, size: 8, value: nil, placeholder: Person.fld(:national_id, :short) }
			],
			[
				gap_field(size: 0),
				{ kind: :label_checkbox, label: Person.t_path(:sex, :female), key: :female, value: registration.candidate_female, align: :left }
			],
			[
				symbol_field(:person, { title: Registration.fld(:requester) }),
				{ kind: :label, value: Registration.fld(:requester), cols: 4 }
			],
			[
				gap_field(size: 0),
				{ kind: :text_box, key: :requester_name, size: 38, value: registration.requester_name, placeholder: Person.fld(:name), mandatory: { length: 2 }, cols: 4 }
			],
			[
				gap_field(size: 0)
			],
			[
				gap_field(size: 0),
				{ kind: :email_box, key: :requester_email, value: registration.requester_email, placeholder: Person.val(:email), mandatory: { length: 7 } },
				gap_field(size: 1),
				symbol_field(:call, { title: Person.fld(:phone) }),
				{ kind: :text_box, key: :phone, size: 12, value: registration.requester_phone, placeholder: Person.fld(:phone) }
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
