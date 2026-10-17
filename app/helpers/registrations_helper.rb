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
		icon     = registration.club&.logo
		title    = registration.club&.nick || Server.server_name
		title   += " - #{Registration.label}"
		subtitle = @team ?
			"#{@team} - #{@team.season.name}" :
			registration.kind_label

		header = title_start(icon:, title:, subtitle:)
		header[1].last[:cols] = 3
		header[0] += [
			gap_item,
			participation_status_field(registration)
		]

		header
	end

	# fields to show when looking a registration request
	def registration_show_header(registration = @registration)
		fields = person_show_title(registration, title: Registration.fld(:candidate))
		fields[3][1][:cols] = 2
		fields[4][0] = gap_item
		fields << [ label_item(Relationship.kind_label(:guardian, :plural), cols: 3) ] if registration.candidate.minor?
		fields
	end

	def registration_show_fields(registration = @registration)
		fields = []
		unless registration.guardian1.blank?
			fields += person_summary_fields(registration.guardian1, prepend_gap: true)
			fields += person_summary_fields(registration.guardian2, prepend_gap: true) if registration.guardian2
		end
		unless registration.requester_kind == "self" || registration.requester.blank? || registration.requester == registration.guardian1
			fields << [ label_item(registration.fld(:requester), cols: 3) ]
			fields += person_summary_fields(registration.requester, prepend_gap: true)
		end
		fields
	end

	#
	def registration_form_header(registration = @registration, action: :edit)
		person_form_title(
			registration,
			icon: registration.candidate,
			title: registration.act(action),
			sex: true,
			guardians: true
		)
	end

	#
	def registration_requester_form_fields(registration = @registration, action: :edit)
		person_contact_form_fields(registration.requester, required: true)
	end

	#
	def registration_form_fields(registration = @registration, action: :show)
		fields = []
		fields << [
			# TODO: SPAN OF FIRST FIELD IS WIDER THANB INTENDED FOR SOME UNKNOWN REASON
			symbol_item(:team, { title: Team.label }, align: :right),
			{ kind: :select_box, key: :requested_team_id, options: @team.club.open_team_list, value: @team },
			hidden_input(:kind, registration.kind || @kind)
		] if @team

		fields.last << hidden_input(:token, @token) if @token

		fields += [
			[ { kind: :text_area, key: :remarks, value: registration.remarks, placeholder: registration.fld(:remarks), size: 36, lines: 2, cols: 3 } ]
		]

		if doc = registration.club.payment_terms_template
			return fields unless doc.file.attached?

			payment_form = registration.payment_terms.attached? ? registration.payment_terms : nil
			fields += [
				[
					normal_button({ kind: :link, symbol: symbol_hash(:document, size: "25x25"), url: rails_blob_path(doc.file, disposition: "attachment"), label: doc.kind_label }, cols: 3)
				],
				[ upload_button(:payment_terms, doc.kind_label, payment_form, cols: 3) ]
			]
		end

		fields
	end

	# fields to show when looking a user profile
	def registration_status_form_fields(registration = @registration)
	end

	# return table for @registrations TableComponent definition
	def registrations_table(registrations = @registrations)
		{
			title: registrations_table_header,
			rows: registrations_table_rows(registrations)
		}
	end

	# return registration TableComponent definition
	def registration_messages_table(messages)
		return if messages.empty?

		title = [
			{ kind: :normal, value: RegistrationMessage.fld(:sent_short) },
			{ kind: :normal, value: RegistrationMessage.fld(:author) },
			{ kind: :normal, value: RegistrationMessage.fld(:body) }
		]

		rows  = []
		messages.each do |msg|
			items = [
				{ kind: :normal, value: msg.created_at.to_date },
				{ kind: :normal, value: msg.author_label },
				{ kind: :normal, value: msg.body }
			]
			rows << { url: "#", items: }
		end
		{ title:, rows: }
	end

	def registration_button(action, frame: :modal, data: {})
		action = action.to_sym
		data   = data.merge(confirm: Registration.que(action))
		url    = path_for(@registration, action:),

		normal_button(
			{
				kind: :action,
				label: Registration.act(action),
				url:,
				frame:,
				data:
			}
		)
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
					row[:items] << icon_item(reg.club.logo, title: reg.club.nick, align: :center)
				end

				row[:items] << { kind: :normal, value: reg.requested_team ? reg.requested_team.name : "-" }

				row[:items] += [
					{ kind: :normal, value: reg.kind_label },
					{ kind: :normal, value: "#{reg.candidate.name} #{reg.candidate.surname}" },
					{ kind: :normal, value: I18n.t("admissions.registration_statuses.values.#{reg.status}.single") },
					{ kind: :normal, value: reg.updated_at.to_date }
				]
				rows << row
			end

			rows
		end
end
