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
			label_field(Registration.act(action))
		] if @team

		header
	end

	# fields to show when looking a registration request
	def registration_show_fields(registration = @registration)
		fields = [
			[	gap_field(size: 0), label_field(registration.s_name) ],
			[]
		]

		fields
	end

	#
	def registration_form_header(registration = @registration, action: :edit)
		header = person_form_title(
			registration,
			icon: registration.candidate,
			title: registration.act(action),
			sex: true,
			guardians: true
		)
		header[2] += [ gap_field(size: 0), label_field(@team.name, cols: 2) ] if @team
		header
	end

	#
	def registration_requester_form_fields(registration = @registration, action: :edit)
		person_contact_form_fields(registration.requester, required: true)
	end

	#
	def registration_form_fields(registration = @registration, action: :show)
		fields = [
			[
				label_field(registration.fld(:remarks), cols: 2),
				{ kind: :hidden, key: :kind, value: registration.kind || @kind },
				{ kind: :hidden, key: :requested_team_id, value: @team.id }
			],
			[ { kind: :text_area, key: :remarks, value: registration.remarks, size: 36, lines: 2, cols: 2 } ]
		]

		if doc = registration.club.payment_terms_template
			return fields unless doc.file.attached?

			payment_form = registration.payment_terms.attached? ? registration.payment_terms : nil
			fields += [
				[
					button_field({ kind: :link, symbol: symbol_hash(:document, size: "25x25"), url: rails_blob_path(doc.file, disposition: "attachment"), label: doc.kind_label })
				],
				[ form_file_field(label: doc.kind_label, key: :payment_terms, value: payment_form, cols: 2) ]
			]
		end

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
