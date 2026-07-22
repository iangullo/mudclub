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
#
# Catalog::Permissions
#
# Define the premissions applicable to the MudClub Core module
#
class Catalog::Permissions < Catalog::Base
	CATALOG = {

		#
		# Club administration
		#

		view_club: {
			id: 10,
			scope: :club,
			description:
				"View club information and configuration."
		},

		manage_club: {
			id: 20,
			scope: :club,
			description:
				"Manage club information and configuration."
		},

		view_people: {
			id: 30,
			scope: :club,
			description:
				"View personal information of club members."
		},

		contact_people: {
			id: 40,
			scope: :club,
			description: "Contact people using the communication services provided by MudClub."
		},

		manage_people: {
			id: 40,
			scope: :club,
			description:
				"Create and maintain people records."
		},

		view_roles: {
			id: 50,
			scope: :club,
			description:
				"View operational roles."
		},

		manage_roles: {
			id: 60,
			scope: :club,
			description:
				"Define operational roles."
		},

		#
		# System administration
		#

		view_system: {
			id: 100,
			scope: :global,
			description:
				"View system-wide configuration and status."
		},

		manage_system: {
			id: 110,
			scope: :global,
			description:
				"Administer the MudClub installation."
		},

		manage_users: {
			id: 120,
			scope: :global,
			description:
				"Manage MudClub user accounts."
		}

	}.freeze
end
