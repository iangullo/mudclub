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
# View helpers for MudClub Membership views
module MembershipsHelper
	# return title for @people TableComponent
	def memberships_table(members:)
		{ title: memberships_table_title, rows: memberships_table_rows(members) }
	end

	def memberships_table_title
		title = [
			{ kind: :normal, value: Membership.attr(:kind, :short) },
			{ kind: :normal, value: @kind ? Membership.kind_label(@kind) : Membership.label },
			{ kind: :normal, value: Membership.attr(:joined_on, :short) },
			{ kind: :normal, value: Membership.attr(:status) }
		]
		# optional button to add new member - should be controlled by member policy, not this old control...
		title << button_field({ kind: :add, url: new_club_member_path(@club), frame: "modal" }) if club_manager?
	end

	def memberships_table_rows(members)
			rows = Array.new
			members.each { |member|
				row = { url: club_member_path(@club, member), items: [] }

				row[:items] << participation_kind_field(member, class: "border")
				row[:items] << person_name_field(member)
				row[:items] << { kind: :normal, value: member.joined_on }
				row[:items] << participation_status_field(member, f_opts: { align: "center", class: "border" })
				rows << row
			}
			rows
	end

	def membership_details_fields(member)
		fields = [
			[
				{ kind: :label, value: member.label, align: "center" },
				gap_field,
				{ kind: :label, value: "#{member.attr(:joined_on, :short)}: ", align: "left" },
				{ kind: :string, value: date_string(member.joined_on), align: "left", class: "items-center" }
			]
		]

		if member.left_on
			fields <<	[
				gap_field(cols: 2),
				{ kind: :label, value: "#{member.attr(:left_on, :short)}: ", align: "left" },
				{ kind: :string, value: date_string(member.left_on), align: "left", class: "items-center" }
			]
		end
		fields
	end

	def membership_show_fields(member)
		[
			[
				{ kind: :label, value: "#{member.attr(:notes)}: ", align: "right", class: "text-right" },
				{ kind: :text_field, value: member.notes, align: "left" }
			],
			[	{ kind: :label, value: "#{Assignment.label(:plural)}:", cols: 2 }	]
		]
	end

	def membership_form_title(member, action)
		person_form_title(
			member,
			icon: member.picture,
			title: Membership.t_path(:action, action.to_sym),
			sex: true
		)
	end

	def membership_form_fields(member)
	[
		[ { kind: :label, value: Membership.attr(:notes) } ],
		[	{ kind: :rich_text_area, key: :notes, cols: 3 } ]
	]
	end

	def membership_form_path
		if @member&.persisted?
			club_member_path(@club, @member)
		else
			club_members_path(@club)
		end
	end
end
