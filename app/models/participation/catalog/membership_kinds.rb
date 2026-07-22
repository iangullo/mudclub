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
# Catalog::MembershipKinds
#
# Defines the recognised categories of membership within a club.
#
# Membership kinds describe why a person belongs to a club.
#
# Each kind declares the organisational namespaces in which members
# of that kind normally participate. Members may simultaneously hold
# multiple memberships, allowing them to contribute across several
# organisational domains.
#
class Catalog::MembershipKinds < Catalog::Base
	CATALOG = {

		athlete: {
			id: 0,
			scope: :club,

			namespaces: [
				:coaching,
				:competition
			],

			description:
				"Member participating as an athlete in one or more sporting activities."
		},

		coach: {
			id: 10,
			scope: :club,

			namespaces: [
				:coaching,
				:competition
			],

			description:
				"Member belonging to the club's coaching staff."
		},

		volunteer: {
			id: 20,
			scope: :club,

			namespaces: [
				:communications,
				:events,
				:operations
			],

			description:
				"Member collaborating voluntarily in support of the club."
		},

		board_member: {
			id: 30,
			scope: :club,

			namespaces: [
				:core,
				:finance,
				:communications,
				:operations
			],

			description:
				"Member serving on the club's governing board."
		},

		club_manager: {
			id: 40,
			scope: :club,
			namespaces: [
				:core,
				:operations
			],

			description: "Member responsible for the operational management of the club."
		}

	}.freeze
end
