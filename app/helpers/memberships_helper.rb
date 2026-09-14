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
		participation_table(members.reorder(:joined_on), kind: @kind)
	end

	def membership_details_fields(member)
		fields = [
			[
				{ kind: :label, value: member.label, align: "center" },
				gap_field,
				{ kind: :label, value: "#{member.fld(:joined_on, :short)}: ", align: "left" },
				{ kind: :string, value: date_string(member.joined_on), align: "left", class: "items-center" }
			]
		]

		if member.left_on
			fields <<	[
				gap_field(cols: 2),
				{ kind: :label, value: "#{member.fld(:left_on, :short)}: ", align: "left" },
				{ kind: :string, value: date_string(member.left_on), align: "left", class: "items-center" }
			]
		end
		fields
	end

	def membership_show_fields(member)
		[
			[
				{ kind: :label, value: "#{member.fld(:notes)}: ", align: "right", class: "text-right" },
				{ kind: :text_field, value: member.notes, align: "left" }
			],
			[	{ kind: :label, value: "#{Assignment.label(:plural)}:", cols: 2 }	]
		]
	end

	def membership_form_title(member, action)
		person_form_title(
			member,
			icon: member.picture,
			title: Membership.act(action.to_sym),
			sex: true
		)
	end

	def membership_form_fields(member)
	[
		[ { kind: :label, value: Membership.fld(:notes) } ],
		[
			{ kind: :rich_text_area, key: :notes, cols: 3 },
			{ kind: :hidden, key: :kind, value: member.kind }
		]
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
