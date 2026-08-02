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
	def members_table(members:)
		{ title: members_table_title, rows: members_table_rows(members) }
	end

	def members_table_title
		title = [
			{ kind: :normal, value: Membership.attr(:kind, :short) },
			{ kind: :normal, value: Membership.label },
			{ kind: :normal, value: Membership.attr(:joined_on, :short) },
			{ kind: :normal, value: Membership.attr(:status) }
		]
		# optional button to add new membership - shoudl be controlled by membership policy, not this old control...
		title << button_field({ kind: :add, url: new_club_member_path(@clubid), frame: "modal" }) if club_manager?
	end

	def members_table_rows(members)
			rows = Array.new
			members.each { |member|
				row = { url: club_member_path(@clubid, member), frame: "modal", items: [] }

				row[:items] << membership_kind_field(member)
				row[:items] << person_name_field(member)
				row[:items] << { kind: :normal, value: member.joined_on }
				row[:items] << membership_status_field(member, class: "align-top border")
				rows << row
			}
			rows
	end

	def membership_kind_field(member, align: "center", class: nil)
		symbol =
			Catalog::MembershipKinds.normalize(member.kind) || :person

		symbol_field(
			symbol,
			{ title: Catalog::MembershipKinds.val(member.kind, :hint) },
			align:,
			class:
		)
	end

	def membership_status_field(member, align: "center", class: nil)
		symbol_field(
			"status",
			{ variant: member.status, title: I18n.t("shared.statuses.#{member.status}") },
			align:,
			class:
		)
	end

	def member_show_fields(member)
		l_since = "#{I18n.t('calendar.fields.since')}: "
		l_since +=
			if member.joined_on
				date_string(member.joined_on)
			else
				"(#{I18n.t("shared.statuses.pending")})"
			end

		l_until = "#{I18n.t('calendar.fields.until')}: "
		l_until +=
			if member.left_on
				date_string(member.left_on)
			else
				"-"
			end

		[
			[
				membership_status_field(member),
				{ kind: :string, value: l_since, cols: 3, align: "left" }
			],
			[ gap_field, { kind: :string, value: l_until, cols: 3, align: "left" } ]
		]
	end
end
